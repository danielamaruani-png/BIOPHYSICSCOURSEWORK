#include "MyBlueprintFunctionLibrary.h"
#include "Misc/FileHelper.h"
#include "Misc/Paths.h"
#include "Misc/DateTime.h"
#include "HAL/PlatformFilemanager.h"

namespace
{
	// In-memory only: not persisted, so it resets whenever the editor/game restarts.
	int32 GCurrentAttemptNumber = 0;

	// Empty until first needed, then holds a per-session timestamp used in both CSV file
	// names. Cleared by ResetSession() so the next write starts a brand new pair of files.
	FString GSessionTimestamp;

	const FString& GetSessionTimestamp()
	{
		if (GSessionTimestamp.IsEmpty())
		{
			GSessionTimestamp = FDateTime::Now().ToString(TEXT("%Y.%m.%d-%H.%M.%S"));
		}
		return GSessionTimestamp;
	}

	// Makes sure the folder exists and the file has its header row before anything writes to it.
	void EnsureFileWithHeaderExists(const FString& FilePath, const FString& Header)
	{
		IFileManager& FileManager = IFileManager::Get();

		const FString Directory = FPaths::GetPath(FilePath);
		if (!FileManager.DirectoryExists(*Directory))
		{
			FileManager.MakeDirectory(*Directory, /*Tree=*/true);
		}

		if (!FileManager.FileExists(*FilePath))
		{
			FFileHelper::SaveStringToFile(Header, *FilePath);
		}
	}

	// Ball velocity/direction and pin count live in separate files so one can't be misread as
	// part of the other, and each carries the shared AttemptNumber to line rows back up.
	FString GetOrInitBallDataFilePath()
	{
		const FString FilePath = FPaths::Combine(
			FPaths::ProjectSavedDir(), TEXT("BowlingData"),
			FString::Printf(TEXT("BallData_%s.csv"), *GetSessionTimestamp()));

		EnsureFileWithHeaderExists(FilePath, TEXT("AttemptNumber,BallVelocity,DirectionX,DirectionY,DirectionZ\n"));
		return FilePath;
	}

	FString GetOrInitPinsDataFilePath()
	{
		const FString FilePath = FPaths::Combine(
			FPaths::ProjectSavedDir(), TEXT("BowlingData"),
			FString::Printf(TEXT("PinsData_%s.csv"), *GetSessionTimestamp()));

		EnsureFileWithHeaderExists(FilePath, TEXT("AttemptNumber,PinsKnockedDown\n"));
		return FilePath;
	}
}

FBowlingAttemptRecord UMyBlueprintFunctionLibrary::RecordAttempt(int32 PinsKnockedDown, float BallVelocity, FVector BallDirection)
{
	++GCurrentAttemptNumber;

	FBowlingAttemptRecord Record;
	Record.AttemptNumber = GCurrentAttemptNumber;
	Record.PinsKnockedDown = FMath::Clamp(PinsKnockedDown, 0, 10);
	Record.BallVelocity = FMath::Max(0.0f, BallVelocity);
	// Normalize here so the caller doesn't have to remember to; direction and speed
	// are logged as separate columns rather than one combined velocity vector.
	Record.BallDirection = BallDirection.GetSafeNormal();

	const FString BallLine = FString::Printf(
		TEXT("%d,%.2f,%.4f,%.4f,%.4f\n"),
		Record.AttemptNumber,
		Record.BallVelocity,
		Record.BallDirection.X,
		Record.BallDirection.Y,
		Record.BallDirection.Z);

	// Append, not overwrite: every throw within this session accumulates in the same file.
	FFileHelper::SaveStringToFile(
		BallLine,
		*GetOrInitBallDataFilePath(),
		FFileHelper::EEncodingOptions::AutoDetect,
		&IFileManager::Get(),
		FILEWRITE_Append);

	const FString PinsLine = FString::Printf(
		TEXT("%d,%d\n"),
		Record.AttemptNumber,
		Record.PinsKnockedDown);

	// Separate file from ball data on purpose, so a pin-count bug can never be mistaken
	// for corrupted velocity/direction columns (or vice versa) when inspecting the CSVs.
	FFileHelper::SaveStringToFile(
		PinsLine,
		*GetOrInitPinsDataFilePath(),
		FFileHelper::EEncodingOptions::AutoDetect,
		&IFileManager::Get(),
		FILEWRITE_Append);

	return Record;
}

void UMyBlueprintFunctionLibrary::ResetSession()
{
	GCurrentAttemptNumber = 0;
	// Clearing this forces GetSessionTimestamp() to mint a new one on the next file write,
	// which in turn makes GetOrInit*FilePath() start writing to a brand new pair of files.
	GSessionTimestamp.Empty();
}

FString UMyBlueprintFunctionLibrary::GetBallDataFilePath()
{
	return GetOrInitBallDataFilePath();
}

FString UMyBlueprintFunctionLibrary::GetPinsDataFilePath()
{
	return GetOrInitPinsDataFilePath();
}

bool UMyBlueprintFunctionLibrary::LoadAllRecords(TArray<FBowlingAttemptRecord>& OutRecords)
{
	OutRecords.Empty();

	TMap<int32, FBowlingAttemptRecord> RecordsByAttempt;

	FString BallFileContent;
	if (FFileHelper::LoadFileToString(BallFileContent, *GetOrInitBallDataFilePath()))
	{
		TArray<FString> Lines;
		BallFileContent.ParseIntoArrayLines(Lines);

		// Start at 1 to skip the header row.
		for (int32 i = 1; i < Lines.Num(); ++i)
		{
			if (Lines[i].IsEmpty())
			{
				continue;
			}

			TArray<FString> Columns;
			Lines[i].ParseIntoArray(Columns, TEXT(","));

			if (Columns.Num() == 5)
			{
				FBowlingAttemptRecord Record;
				Record.AttemptNumber = FCString::Atoi(*Columns[0]);
				Record.BallVelocity = FCString::Atof(*Columns[1]);
				Record.BallDirection = FVector(
					FCString::Atof(*Columns[2]),
					FCString::Atof(*Columns[3]),
					FCString::Atof(*Columns[4]));
				RecordsByAttempt.Add(Record.AttemptNumber, Record);
			}
		}
	}

	FString PinsFileContent;
	if (FFileHelper::LoadFileToString(PinsFileContent, *GetOrInitPinsDataFilePath()))
	{
		TArray<FString> Lines;
		PinsFileContent.ParseIntoArrayLines(Lines);

		for (int32 i = 1; i < Lines.Num(); ++i)
		{
			if (Lines[i].IsEmpty())
			{
				continue;
			}

			TArray<FString> Columns;
			Lines[i].ParseIntoArray(Columns, TEXT(","));

			if (Columns.Num() == 2)
			{
				const int32 AttemptNumber = FCString::Atoi(*Columns[0]);
				const int32 PinsKnockedDown = FCString::Atoi(*Columns[1]);

				// A pins-file row with no matching ball-file row (or vice versa) shouldn't
				// happen since both are written together in RecordAttempt, but Find() keeps
				// this robust rather than silently fabricating a record for such a case.
				if (FBowlingAttemptRecord* Existing = RecordsByAttempt.Find(AttemptNumber))
				{
					Existing->PinsKnockedDown = PinsKnockedDown;
				}
			}
		}
	}

	RecordsByAttempt.GenerateValueArray(OutRecords);
	OutRecords.Sort([](const FBowlingAttemptRecord& A, const FBowlingAttemptRecord& B)
	{
		return A.AttemptNumber < B.AttemptNumber;
	});

	// Keep numbering continuous with what's already on disk, rather than restarting at 1
	// and overwriting/duplicating attempt numbers on the next RecordAttempt call.
	if (OutRecords.Num() > 0)
	{
		GCurrentAttemptNumber = OutRecords.Last().AttemptNumber;
	}

	return true;
}
