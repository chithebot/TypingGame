INCLUDE Irvine32.inc

; Constants
TRUE = 1
FALSE = 0
BUFFER_SIZE = 85000						; max size for file buffer
STRING_BUFFER_SIZE = 20					; max for string buffer for extracting strings from file buffer
CONSOLE_WINDOW_MAX_X = 119				; console window x-axis bound
CONSOLE_WINDOW_MAX_Y = 29				; console window y-axis bound
MILLISECONDS_PER_FRAME = 17				; milliseconds per frame in 60FPS
MILLISECONDS_PER_SECOND = 1000

; Keyboard Constants
ESC_KEY = 27

; typingGame.asm
RunTypingGame PROTO
RunLevel PROTO
ExtractRandomWord PROTO
GenerateRandomWordAttributes PROTO
GenerateRandomWords PROTO
ClearRandomWordArray PROTO
LevelStartDisplay PROTO
SpawnRandomWord PROTO
SpawnNow PROTO
SearchRandomWordArray PROTO
Update PROTO
Clear PROTO
Draw PROTO
GetRandomWordAt PROTO
ScoreCounting PROTO
GameLevelExitCondition PROTO
LevelEndDisplay PROTO

; fileIO.asm
ReadFileIntoBuffer PROTO
DeallocateBuffer PROTO

; displayText.asm
DisplayTextAt PROTO
ClearTextAt PROTO
DefaultTextColor PROTO
EmptyTextColor PROTO

; dynamicMemory.asm
AllocateMemory PROTO
FreeMemory PROTO

; string.asm
ConstructString PROTO
DestroyString PROTO
GetStringLength PROTO
GetCharacterAt PROTO

; randomWord.asm
ConstructRandomWord PROTO
DestroyRandomWord PROTO
GetString PROTO							; accessors
GetXPosition PROTO
GetYPosition PROTO
GetXVelocity PROTO
GetYVelocity PROTO
GetCorrectCharacters PROTO
IsSpawned PROTO
IsHidden PROTO
GetFramesPerMovement PROTO
IsCompleted PROTO
IsOutOfXBounds PROTO
IsOutOfYBounds PROTO
GetLength PROTO
GetCurrentCharacter PROTO
GetRightCorner PROTO
SetXPosition PROTO						; mutators
SetYPosition PROTO
SetXVelocity PROTO
SetYVelocity PROTO
SetCorrectCharacters PROTO
SetSpawnedState PROTO
SetHiddenState PROTO
SetFramesPerMovement PROTO
AddXPosition PROTO
AddYPosition PROTO
IncrementCorrectCharacters PROTO
ToggleSpawned PROTO
ToggleHidden PROTO
OutOfXBounds PROTO
Bounce PROTO
UpdateRandomWord PROTO
ClearRandomWord PROTO
DrawRandomWord PROTO

; tools.asm
RandomInt32Range PROTO
ClearStringBuffer PROTO
ConvertIndexToDWORDIndex PROTO
GetMiddleOfConsole PROTO
GetMidpoint PROTO
GetMidpointOfString PROTO
IsValidChar PROTO
DisplayStringAtMiddle PROTO
