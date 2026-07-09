#include "MyBlueprintFunctionLibrary.h"
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
			const FString Header = TEXT("AttemptNumber,PinsKnockedDown,BallVelocity,DirectionX,DirectionY,DirectionZ\n");
			FFileHelper::SaveStringToFile(Header, *SaveFilePath);
		}

		return SaveFilePath;
	}
}

FBowlingAttemptRecord UMyBlueprintFunctionLibrary::RecordAttempt(int32 PinsKnockedDown, float BallVelocity, FVector BallDirection)
{
	const FString SaveFilePath = GetOrInitSaveFilePath();

	++GCurrentAttemptNumber;

	FBowlingAttemptRecord Record;
	Record.AttemptNumber = GCurrentAttemptNumber;
	Record.PinsKnockedDown = FMath::Clamp(PinsKnockedDown, 0, 10);
	Record.BallVelocity = FMath::Max(0.0f, BallVelocity);
	Record.BallDirection = BallDirection.GetSafeNormal();

	const FString Line = FString::Printf(
		TEXT("%d,%d,%.2f,%.4f,%.4f,%.4f\n"),
		Record.AttemptNumber,
		Record.PinsKnockedDown,
		Record.BallVelocity,
		Record.BallDirection.X,
		Record.BallDirection.Y,
		Record.BallDirection.Z);

	FFileHelper::SaveStringToFile(
		Line,
		*SaveFilePath,
		FFileHelper::EEncodingOptions::AutoDetect,
		&IFileManager::Get(),
		FILEWRITE_Append);

	return Record;
}

void UMyBlueprintFunctionLibrary::ResetSession()
{
	GCurrentAttemptNumber = 0;
}

FString UMyBlueprintFunctionLibrary::GetSaveFilePath()
{
	return GetOrInitSaveFilePath();
}

bool UMyBlueprintFunctionLibrary::LoadAllRecords(TArray<FBowlingAttemptRecord>& OutRecords)
{
	OutRecords.Empty();

	const FString SaveFilePath = GetOrInitSaveFilePath();

	FString FileContent;
	if (!FFileHelper::LoadFileToString(FileContent, *SaveFilePath))
	{
		return false;
	}

	TArray<FString> Lines;
	FileContent.ParseIntoArrayLines(Lines);

	for (int32 i = 1; i < Lines.Num(); ++i)
	{
		if (Lines[i].IsEmpty())
		{
			continue;
		}

		TArray<FString> Columns;
		Lines[i].ParseIntoArray(Columns, TEXT(","));

		if (Columns.Num() == 6)
		{
			FBowlingAttemptRecord Record;
			Record.AttemptNumber = FCString::Atoi(*Columns[0]);
			Record.PinsKnockedDown = FCString::Atoi(*Columns[1]);
			Record.BallVelocity = FCString::Atof(*Columns[2]);
			Record.BallDirection = FVector(
				FCString::Atof(*Columns[3]),
				FCString::Atof(*Columns[4]),
				FCString::Atof(*Columns[5]));
			OutRecords.Add(Record);
		}
	}

	if (OutRecords.Num() > 0)
	{
		GCurrentAttemptNumber = OutRecords.Last().AttemptNumber;
	}

	return true;
}
