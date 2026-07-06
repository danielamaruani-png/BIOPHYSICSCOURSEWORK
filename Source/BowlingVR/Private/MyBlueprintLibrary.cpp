#include "MyBlueprintLibrary.h"
#include "Misc/FileHelper.h"
#include "Misc/Paths.h"
#include "HAL/PlatformFilemanager.h"

namespace
{
	int32 GCurrentAttemptNumber = 0;

	FString GetOrInitSaveFilePath()
	{
		static const FString SaveFilePath = FPaths::Combine(
			FPaths::ProjectSavedDir(), TEXT("BowlingData"), TEXT("BowlingResults.csv"));

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

		return SaveFilePath;
	}
}

FBowlingAttemptRecord UMyBlueprintLibrary::RecordAttempt(int32 PinsKnockedDown, float BallVelocity)
{
	const FString SaveFilePath = GetOrInitSaveFilePath();

	++GCurrentAttemptNumber;

	FBowlingAttemptRecord Record;
	Record.AttemptNumber = GCurrentAttemptNumber;
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

void UMyBlueprintLibrary::ResetSession()
{
	GCurrentAttemptNumber = 0;
}

FString UMyBlueprintLibrary::GetSaveFilePath()
{
	return GetOrInitSaveFilePath();
}
