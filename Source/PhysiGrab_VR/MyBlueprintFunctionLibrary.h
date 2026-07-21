#pragma once

#include "CoreMinimal.h"
#include "Kismet/BlueprintFunctionLibrary.h"
#include "MyBlueprintFunctionLibrary.generated.h"

// One row of data for a single bowling throw.
USTRUCT(BlueprintType)
struct FBowlingAttemptRecord
{
	GENERATED_BODY()

	// Auto-incremented per call to RecordAttempt; resets when the editor/game restarts.
	UPROPERTY(BlueprintReadOnly, Category = "Bowling|File IO")
	int32 AttemptNumber = 0;

	// Clamped to [0, 10] in RecordAttempt.
	UPROPERTY(BlueprintReadOnly, Category = "Bowling|File IO")
	int32 PinsKnockedDown = 0;

	// Clamped to >= 0 in RecordAttempt. Unit depends on what the caller passes in (see Blueprint side).
	UPROPERTY(BlueprintReadOnly, Category = "Bowling|File IO")
	float BallVelocity = 0.f;

	// Normalized (length 1) direction the ball was thrown in; speed is not encoded here.
	UPROPERTY(BlueprintReadOnly, Category = "Bowling|File IO")
	FVector BallDirection = FVector::ZeroVector;
};

// Blueprint-exposed file I/O for logging bowling attempts, since Blueprint alone
// has no way to write an arbitrary text file to disk.
UCLASS()
class PHYSIGRAB_VR_API UMyBlueprintFunctionLibrary : public UBlueprintFunctionLibrary
{
	GENERATED_BODY()

public:
	// Call once per throw. Appends one CSV row and returns the record that was written.
	UFUNCTION(BlueprintCallable, Category = "Bowling|File IO")
	static FBowlingAttemptRecord RecordAttempt(int32 PinsKnockedDown, float BallVelocity, FVector BallDirection);

	// Resets the in-memory attempt counter to 0 and starts a new pair of timestamped CSV files
	// for both ball-throw and pins-knocked-down data. Call this once per game session (e.g. from
	// Event BeginPlay) to get a fresh set of files every time you play.
	UFUNCTION(BlueprintCallable, Category = "Bowling|File IO")
	static void ResetSession();

	// Full path to the ball-throw CSV file for the current session (created on first write,
	// under Saved/BowlingData/). A fresh file is used each time ResetSession() is called.
	UFUNCTION(BlueprintPure, Category = "Bowling|File IO")
	static FString GetBallDataFilePath();

	// Full path to the pins-knocked-down CSV file for the current session. Kept separate from
	// the ball-throw file so pin-counting data never shares rows with ball velocity/direction.
	UFUNCTION(BlueprintPure, Category = "Bowling|File IO")
	static FString GetPinsDataFilePath();

	// Reads the CSV back into OutRecords, for reviewing/analyzing past attempts from Blueprint.
	UFUNCTION(BlueprintCallable, Category = "Bowling|File IO")
	static bool LoadAllRecords(TArray<FBowlingAttemptRecord>& OutRecords);
};
