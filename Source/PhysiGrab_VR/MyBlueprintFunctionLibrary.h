#pragma once

#include "CoreMinimal.h"
#include "Kismet/BlueprintFunctionLibrary.h"
#include "MyBlueprintFunctionLibrary.generated.h"

USTRUCT(BlueprintType)
struct FBowlingAttemptRecord
{
	GENERATED_BODY()

	UPROPERTY(BlueprintReadOnly, Category = "Bowling|File IO")
	int32 AttemptNumber = 0;

	UPROPERTY(BlueprintReadOnly, Category = "Bowling|File IO")
	int32 PinsKnockedDown = 0;

	UPROPERTY(BlueprintReadOnly, Category = "Bowling|File IO")
	float BallVelocity = 0.f;

	UPROPERTY(BlueprintReadOnly, Category = "Bowling|File IO")
	FVector BallDirection = FVector::ZeroVector;
};

UCLASS()
class PHYSIGRAB_VR_API UMyBlueprintFunctionLibrary : public UBlueprintFunctionLibrary
{
	GENERATED_BODY()

public:
	UFUNCTION(BlueprintCallable, Category = "Bowling|File IO")
	static FBowlingAttemptRecord RecordAttempt(int32 PinsKnockedDown, float BallVelocity, FVector BallDirection);

	UFUNCTION(BlueprintCallable, Category = "Bowling|File IO")
	static void ResetSession();

	UFUNCTION(BlueprintPure, Category = "Bowling|File IO")
	static FString GetSaveFilePath();

	UFUNCTION(BlueprintCallable, Category = "Bowling|File IO")
	static bool LoadAllRecords(TArray<FBowlingAttemptRecord>& OutRecords);
};
