#pragma once

#include "CoreMinimal.h"
#include "Kismet/BlueprintFunctionLibrary.h"
#include "MyBlueprintLibrary.generated.h"

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
 * Static helpers to persist one CSV row per bowling attempt (attempt number, pins knocked
 * down, ball velocity) to a file outside the packaged content, so results survive between
 * play sessions and can be opened directly in a spreadsheet for analysis.
 */
UCLASS()
class BOWLINGVR_API UMyBlueprintLibrary : public UBlueprintFunctionLibrary
{
	GENERATED_BODY()

public:
	// Call this once per throw, when the ball and pins have settled.
	UFUNCTION(BlueprintCallable, Category = "Bowling|Save")
	static FBowlingAttemptRecord RecordAttempt(int32 PinsKnockedDown, float BallVelocity);

	// Call when starting a fresh game/session if attempt numbering should restart at 1.
	UFUNCTION(BlueprintCallable, Category = "Bowling|Save")
	static void ResetSession();

	UFUNCTION(BlueprintPure, Category = "Bowling|Save")
	static FString GetSaveFilePath();
};
