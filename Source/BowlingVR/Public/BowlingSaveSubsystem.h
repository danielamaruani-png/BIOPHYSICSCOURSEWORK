#pragma once

#include "CoreMinimal.h"
#include "Subsystems/GameInstanceSubsystem.h"
#include "BowlingSaveSubsystem.generated.h"

USTRUCT(BlueprintType)
struct FBowlingAttemptRecord
{
	GENERATED_BODY()

	UPROPERTY(BlueprintReadOnly, Category = "Bowling|Save")
	int32 AttemptNumber = 0;

	UPROPERTY(BlueprintReadOnly, Category = "Bowling|Save")
	int32 PinsKnockedDown = 0;

	UPROPERTY(BlueprintReadOnly, Category = "Bowling|Save")
	float BallVelocity = 0.f;
};

/**
 * Persists one CSV row per bowling attempt (attempt number, pins knocked down, ball velocity)
 * to a file outside the packaged content, so results survive between play sessions and
 * can be opened directly in a spreadsheet for analysis.
 */
UCLASS()
class BOWLINGVR_API UBowlingSaveSubsystem : public UGameInstanceSubsystem
{
	GENERATED_BODY()

public:
	virtual void Initialize(FSubsystemCollectionBase& Collection) override;

	// Call this once per throw, when the ball and pins have settled.
	UFUNCTION(BlueprintCallable, Category = "Bowling|Save")
	FBowlingAttemptRecord RecordAttempt(int32 PinsKnockedDown, float BallVelocity);

	// Call when starting a fresh game/session if attempt numbering should restart at 1.
	UFUNCTION(BlueprintCallable, Category = "Bowling|Save")
	void ResetSession();

	UFUNCTION(BlueprintPure, Category = "Bowling|Save")
	FString GetSaveFilePath() const;

private:
	void EnsureFileReady();

	int32 CurrentAttemptNumber = 0;
	FString SaveFilePath;
};
