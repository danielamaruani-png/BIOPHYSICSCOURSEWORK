#include "BowlingSaveSubsystem.h"
#include "Misc/FileHelper.h"
#include "Misc/Paths.h"
#include "HAL/PlatformFilemanager.h"

void UBowlingSaveSubsystem::Initialize(FSubsystemCollectionBase& Collection)
{
	Super::Initialize(Collection);

	CurrentAttemptNumber = 0;
	SaveFilePath = FPaths::Combine(FPaths::ProjectSavedDir(), TEXT("BowlingData"), TEXT("BowlingResults.csv"));

	EnsureFileReady();
}

void UBowlingSaveSubsystem::EnsureFileReady()
{
	IFileManager& FileManager = IFileManager::Get();

	const FString Directory = FPaths::GetPath(SaveFilePath);
	if (!FileManager.DirectoryExists(*Directory))
	{
		FileManager.MakeDirectory(*Directory, /*Tree=*/true);
	}

	if (!FileManager.FileExists(*SaveFilePath))
	{
		const FString Header = TEXT("AttemptNumber,PinsKnockedDown,BallVelocity\n");
		FFileHelper::SaveStringToFile(Header, *SaveFilePath);
	}
}

FBowlingAttemptRecord UBowlingSaveSubsystem::RecordAttempt(int32 PinsKnockedDown, float BallVelocity)
{
	++CurrentAttemptNumber;

	FBowlingAttemptRecord Record;
	Record.AttemptNumber = CurrentAttemptNumber;
	Record.PinsKnockedDown = PinsKnockedDown;
	Record.BallVelocity = BallVelocity;

	const FString Line = FString::Printf(
		TEXT("%d,%d,%.2f\n"), Record.AttemptNumber, Record.PinsKnockedDown, Record.BallVelocity);

	FFileHelper::SaveStringToFile(
		Line,
		*SaveFilePath,
		FFileHelper::EEncodingOptions::AutoDetect,
		&IFileManager::Get(),
		FILEWRITE_Append);

	return Record;
}

void UBowlingSaveSubsystem::ResetSession()
{
	CurrentAttemptNumber = 0;
}

FString UBowlingSaveSubsystem::GetSaveFilePath() const
{
	return SaveFilePath;
}
