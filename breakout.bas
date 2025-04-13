'$Dynamic
'$Include:'vector.bi'

Randomize Timer

Dim Shared TOTAL_BRICKS As _Unsigned Integer
TOTAL_BRICKS = 8

Const BALL_RADIUS = 10
Const PADDLE_SIZE = 100
Const PADDLE_ERROR = 10

Const GAME_SOUND = 1
Const FPS = 60

Const BRICK_SIZE_X = 50
Const BRICK_SIZE_Y = 20

Type Ball
    As Vec2 Position
    As Vec2 Velocity, oldVelocity
    As Long IMAGE
End Type
Type Brick
    As Vec2 Position, FinalPosition
    As _Unsigned _Byte Alive, Money
    As Long Colour
End Type

Screen _NewImage(960, 540, 32)
Color -1, _RGBA32(0, 0, 0, 127)
_Title "Breakout"
_MouseHide

Dim Shared Balls(0) As Ball, TOTAL_BALLS As _Unsigned Integer, BACKUP_BALLS As _Unsigned Integer, MAX_BALL_SPEED As _Unsigned Integer
Dim Shared Level As _Unsigned Integer
Dim Shared As Vec2 Paddle
Dim Shared As Brick Bricks(0)

Dim Shared As Vec2 ParticlesPosition(0 To 255), ParticlesVelocity(0 To 255)
Dim Shared As Long ParticlesColour(0 To 255)

Paddle.X = _Width / 2
Paddle.Y = 530

BACKUP_BALLS = 3
CreateBall
Dim Shared As _Unsigned _Byte LevelShowTimer
NewLevel

Dim Shared As _Unsigned Long Score

Do
    _Limit FPS
    Cls , _RGB32(15)
    If _WindowHasFocus = 0 Then _Continue
    While _MouseInput
        Paddle.X = Clamp(PADDLE_SIZE / 2, Paddle.X + _MouseMovementX, _Width - PADDLE_SIZE / 2)
        _MouseMove _Width / 2, _Height / 2
    Wend
    Paddle.X = Clamp(PADDLE_SIZE / 2, Paddle.X + (_KeyDown(19200) - _KeyDown(19712)) * 10, _Width - PADDLE_SIZE / 2)
    For B = LBound(Balls) To UBound(Balls)
        If Vec2Length(Balls(B).Velocity) = 0 Then
            NewVec2 Balls(B).Position, Paddle.X, Paddle.Y - BALL_RADIUS
            If _MouseButton(1) Or _KeyDown(32) Then NewVec2 Balls(B).Velocity, Rnd - .5, -1
        End If
        If Vec2Length(Balls(B).Velocity) Then
            Vec2Multiply Balls(B).Velocity, MAX_BALL_SPEED / Vec2Length(Balls(B).Velocity)
            Vec2MultiplyAdd Balls(B).Position, Balls(B).Velocity, 1 / FPS
        End If
        'Simulate Ball Boundary Collision
        Balls(B).Velocity.X = IIF(Balls(B).Position.X > _Width - BALL_RADIUS And Balls(B).Velocity.X > 0, -Balls(B).Velocity.X, Balls(B).Velocity.X)
        Balls(B).Velocity.X = IIF(Balls(B).Position.X < BALL_RADIUS And Balls(B).Velocity.X < 0, -Balls(B).Velocity.X, Balls(B).Velocity.X)
        Balls(B).Velocity.Y = IIF(Balls(B).Position.Y < BALL_RADIUS And Balls(B).Velocity.Y < 0, -Balls(B).Velocity.Y, Balls(B).Velocity.Y)
        If Balls(B).Position.Y > _Height - BALL_RADIUS And Balls(B).Velocity.Y > 0 Then KillBall B: Exit For
        '--------------------------------
        'Simulate Ball Paddle Collision
        If InRange(Paddle.X - PADDLE_SIZE / 2 - PADDLE_ERROR, Balls(B).Position.X, Paddle.X + PADDLE_SIZE / 2 + PADDLE_ERROR) And Balls(B).Position.Y + Balls(B).Velocity.Y / FPS + BALL_RADIUS > Paddle.Y And Balls(B).Velocity.Y > 0 Then
            Balls(B).Velocity.Y = -Balls(B).Velocity.Y
            Balls(B).Velocity.X = 10 * (Balls(B).Position.X - Paddle.X)
        End If
        '------------------------------
        'Simulate Ball Brick Collision
        BRICKS_COUNT = 0 'To count remaining Bricks
        For I = LBound(Bricks) To UBound(Bricks)
            If Bricks(I).Alive = 0 Then _Continue
            BRICKS_COUNT = BRICKS_COUNT + 1
            If (InRange(Bricks(I).Position.X - BALL_RADIUS - BRICK_SIZE_X / 2, Balls(B).Position.X, Bricks(I).Position.X + BALL_RADIUS + BRICK_SIZE_X / 2) And InRange(Bricks(I).Position.Y - BALL_RADIUS - BRICK_SIZE_Y / 2, Balls(B).Position.Y, Bricks(I).Position.Y + BALL_RADIUS + BRICK_SIZE_Y / 2)) = 0 Then _Continue
            BALL_IN_BRICK_X = InRange(Bricks(I).Position.X - BRICK_SIZE_X / 2, Balls(B).Position.X, Bricks(I).Position.X + BRICK_SIZE_X / 2)
            BALL_IN_BRICK_Y = InRange(Bricks(I).Position.Y - BRICK_SIZE_Y / 2, Balls(B).Position.Y, Bricks(I).Position.Y + BRICK_SIZE_Y / 2)
            COLLISION_FROM_TOP = BALL_IN_BRICK_X And Balls(B).Position.Y > Bricks(I).Position.Y - BRICK_SIZE_Y And Balls(B).Velocity.Y > 0
            COLLISION_FROM_BOTTOM = BALL_IN_BRICK_X And Balls(B).Position.Y < Bricks(I).Position.Y + BRICK_SIZE_Y And Balls(B).Velocity.Y < 0
            COLLISION_FROM_LEFT = BALL_IN_BRICK_Y And Balls(B).Position.X > Bricks(I).Position.X - BRICK_SIZE_X And Balls(B).Velocity.X > 0
            COLLISION_FROM_RIGHT = BALL_IN_BRICK_Y And Balls(B).Position.X < Bricks(I).Position.X + BRICK_SIZE_X And Balls(B).Velocity.X < 0
            If COLLISION_FROM_TOP Or COLLISION_FROM_BOTTOM Then Balls(B).Velocity.Y = -Balls(B).Velocity.Y
            If COLLISION_FROM_LEFT Or COLLISION_FROM_RIGHT Then Balls(B).Velocity.X = -Balls(B).Velocity.X
            If (COLLISION_FROM_TOP Or COLLISION_FROM_BOTTOM Or COLLISION_FROM_LEFT Or COLLISION_FROM_RIGHT) = 0 Then
                If Balls(B).Position.X < Bricks(I).Position.X And Balls(B).Velocity.X > 0 Then Balls(B).Velocity.X = -Balls(B).Velocity.X
                If Balls(B).Position.X > Bricks(I).Position.X And Balls(B).Velocity.X < 0 Then Balls(B).Velocity.X = -Balls(B).Velocity.X
                If Balls(B).Position.Y < Bricks(I).Position.Y And Balls(B).Velocity.Y > 0 Then Balls(B).Velocity.Y = -Balls(B).Velocity.Y
                If Balls(B).Position.Y > Bricks(I).Position.Y And Balls(B).Velocity.Y < 0 Then Balls(B).Velocity.Y = -Balls(B).Velocity.Y
            End If
            Bricks(I).Alive = 0
            Score = Score + 5 * TOTAL_BALLS
            Score = Score - 5 * (COLLISION_FROM_TOP Or COLLISION_FROM_BOTTOM Or COLLISION_FROM_LEFT Or COLLISION_FROM_RIGHT)
            Money = Money + Bricks(I).Money
            Particles Bricks(I).Position.X, Bricks(I).Position.Y, Bricks(I).Colour
            PlaySound 2
        Next I
        '-----------------------------
        If BRICKS_COUNT = 0 Then
            PlaySound 3
            NewLevel
        End If
        If Vec2RoundEqual(Balls(B).Velocity, Balls(B).oldVelocity) = 0 Then
            Balls(B).oldVelocity = Balls(B).Velocity
            PlaySound 1
        End If
    Next B

    DrawBricks
    DrawBalls
    DrawBackupBalls
    DrawPaddle
    PlaySound 0
    Particles 0, 0, 0

    Print "Score:"; Score
    If LevelShowTimer < 180 Then
        CenterPrint "Level" + Str$(Level), 0
        LevelShowTimer = LevelShowTimer + Sgn(255 - LevelShowTimer)
    End If
    _Display

    If BACKUP_BALLS + TOTAL_BALLS = 0 Then
        _AutoDisplay
        _MouseShow
        PlaySound 4
        CenterPrint "You Lose", -1
        CenterPrint "Score" + Str$(Score), 0
        For I = 1 To 10
            PlaySound 4
        Next I
        Sleep 1
        CenterPrint "Play Again (Y/N)?", 1
        Sleep
        If _KeyDown(89) Or _KeyDown(121) Then Run Else Exit Do
    ElseIf TOTAL_BALLS = 0 Then
        CreateBall
        BACKUP_BALLS = BACKUP_BALLS - 1
    End If
Loop Until Inp(&H60) = 1
System

Sub CenterPrint (T$, N)
    _PrintString (_Width / 2 - Len(T$) * _FontWidth / 2, _Height / 2 + _FontHeight * (N - 0.5)), T$
End Sub

Sub PlaySound (C)
    Static lC, O
    If (C And O = 10) Or lC < C Then
        lC = C
        O = 1
    End If
    If GAME_SOUND = 0 Then Exit Sub
    Select Case lC
        Case 1: 'Ball
            Select Case O
                Case 1: Sound 250, 1
            End Select
        Case 2: 'Brick
            Select Case O
                Case 1: Sound 300, 1
                Case 2: Sound 350, 1
                Case 3: Sound 400, 1
            End Select
        Case 3: 'New Level
            Select Case O
                Case 1: Sound 600, 1
                Case 2: Sound 600, 1
                Case 3: Sound 900, 1
                Case 4: Sound 900, 1
            End Select
        Case 4: 'Lose
            Select Case O
                Case 1: Sound 600, 1
                Case 2: Sound 600, 1
                Case 3: Sound 450, 1
                Case 4: Sound 450, 1
                Case 5: Sound 300, 1
                Case 6: Sound 300, 1
            End Select
    End Select
    O = O + Sgn(10 - O)
End Sub

Function Vec2Equal (__V1 As Vec2, __V2 As Vec2)
    Vec2Equal = __V1.X = __V2.X And __V1.Y = __V2.Y
End Function
Function Vec2RoundEqual (__V1 As Vec2, __V2 As Vec2)
    Vec2RoundEqual = (Abs(__V1.X - __V2.X) < 0.01) And (Abs(__V1.Y - __V2.Y) < 0.01)
End Function

Sub Particles (X As Integer, Y As Integer, C&)
    Static As _Unsigned _Byte O
    If X Or Y Then
        For I = 0 To 3
            NewVec2 ParticlesPosition(O), X + (Rnd - 0.5) * BRICK_SIZE_X, Y + (Rnd - 0.5) * BRICK_SIZE_Y
            NewVec2 ParticlesVelocity(O), Rnd * 100 - 50, -Rnd * 100
            ParticlesColour(O) = C&
            O = O + 1
        Next I
        Exit Sub
    End If
    For I = 0 To 255
        If Vec2Length(ParticlesVelocity(I)) Then
            Vec2MultiplyAdd ParticlesPosition(I), ParticlesVelocity(I), 1 / FPS
            ParticlesVelocity(I).Y = ParticlesVelocity(I).Y + 10
            If ParticlesPosition(I).Y > _Height Then NewVec2 ParticlesVelocity(I), 0, 0
            If InRange(Paddle.X - PADDLE_SIZE / 2, ParticlesPosition(I).X, Paddle.X + PADDLE_SIZE / 2) And ParticlesPosition(I).Y + BALL_RADIUS > Paddle.Y And ParticlesVelocity(I).Y > 0 Then
                ParticlesVelocity(I).Y = -ParticlesVelocity(I).Y
                ParticlesVelocity(I).X = 10 * (ParticlesPosition(I).X - Paddle.X)
                Score = Score + 1
            End If
            Line (ParticlesPosition(I).X - BRICK_SIZE_X / 20, ParticlesPosition(I).Y - BRICK_SIZE_Y / 20)-(ParticlesPosition(I).X + BRICK_SIZE_X / 20, ParticlesPosition(I).Y + BRICK_SIZE_Y / 20), ParticlesColour(I), BF
        End If
    Next I
End Sub

Sub NewLevel
    ReDim Bricks(0) As Brick
    For I = 1 To TOTAL_BRICKS
        CreateBrick
    Next I
    MAX_BALL_SPEED = 500 + Level * 50
    Level = Level + 1
    TOTAL_BRICKS = Min(TOTAL_BRICKS + 8, 64)
    _Title "Breakout - Level" + Str$(Level)
    LevelShowTimer = 0
    BACKUP_BALLS = BACKUP_BALLS + IIF((Level Mod 5) = 0, 1, 0)
End Sub

Sub CreateBall
    TOTAL_BALLS = TOTAL_BALLS + 1
    Colour& = GetRandomColour
    I = UBound(Balls) + 1
    ReDim _Preserve Balls(1 To I) As Ball
    NewVec2 Balls(I).Velocity, 0, 0
    Balls(I).IMAGE = _NewImage(64, 64, 32)
    _Source Balls(I).IMAGE: _Dest Balls(I).IMAGE: Circle (32, 32), 30, Colour&: Paint (32, 32), Colour&: _Source 0: _Dest 0
End Sub
Sub KillBall (B)
    TOTAL_BALLS = TOTAL_BALLS - 1
    _FreeImage Balls(B).IMAGE
    For I = B To UBound(Balls) - 1: Swap Balls(I), Balls(I + 1): Next I
    ReDim _Preserve Balls(Min(1, I - 1) To I - 1) As Ball
End Sub

Sub CreateBrick
    Static As _Unsigned _Bit * 3 X
    Static As _Unsigned _Bit * 4 Y
    Static As _Unsigned Integer oldLevel
    If Level <> oldLevel Then Y = 0: oldLevel = Level
    BrickID = UBound(Bricks) + 1
    ReDim _Preserve Bricks(1 To BrickID) As Brick
    NewVec2 Bricks(BrickID).FinalPosition, X * 60 + 270, Y * 30 + 75
    NewVec2 Bricks(BrickID).Position, X * 60 + 270, Y * 30 + IIF(Level > 0, -(1 + TOTAL_BRICKS \ 8) * 30, 75)
    Bricks(BrickID).Alive = 1
    Bricks(BrickID).Colour = GetRandomColour
    If Rnd > 0.5 Then Bricks(BrickID).Money = 1
    If Rnd > 0.9 Then Bricks(BrickID).Money = 2
    X = X + 1
    If X = 0 Then Y = Y + 1
End Sub
Sub DrawBricks
    For I = LBound(Bricks) To UBound(Bricks)
        If Bricks(I).Alive = 0 Then _Continue
        Line (Bricks(I).Position.X - BRICK_SIZE_X / 2, Bricks(I).Position.Y - BRICK_SIZE_Y / 2)-(Bricks(I).Position.X + BRICK_SIZE_X / 2, Bricks(I).Position.Y + BRICK_SIZE_Y / 2), Bricks(I).Colour, BF
        dX = Bricks(I).FinalPosition.X - Bricks(I).Position.X
        dY = Bricks(I).FinalPosition.Y - Bricks(I).Position.Y
        Bricks(I).Position.X = Bricks(I).Position.X + Sgn(dX)
        Bricks(I).Position.Y = Bricks(I).Position.Y + Sgn(dY)
    Next I
End Sub
Sub DrawBalls
    For I = LBound(Balls) To UBound(Balls)
        If I <= 0 Then _Continue
        _PutImage (Balls(I).Position.X - BALL_RADIUS, Balls(I).Position.Y - BALL_RADIUS)-(Balls(I).Position.X + BALL_RADIUS, Balls(I).Position.Y + BALL_RADIUS), Balls(I).IMAGE
    Next I
End Sub
Sub DrawBackupBalls
    For I = LBound(Balls) To UBound(Balls)
        BALL_IN_AREA = IIF(InRange(_Width - (BACKUP_BALLS * 3 + 1) * BALL_RADIUS, Balls(I).Position.X, _Width) And Balls(I).Position.Y < 64 + BALL_RADIUS, 1, BALL_IN_AREA)
    Next I
    If BALL_IN_AREA Then Colour& = _RGBA32(255, 255, 255, 127) Else Colour& = -1
    For I = 1 To BACKUP_BALLS
        Circle (_Width - BALL_RADIUS * (3 * I - 1), 32), BALL_RADIUS, Colour&
        Circle (_Width - BALL_RADIUS * (3 * I - 1), 32), BALL_RADIUS - 1, Colour&
    Next I
End Sub
Sub DrawPaddle
    For I = 0 To 3
        Line (Paddle.X - PADDLE_SIZE / 2 - I, Paddle.Y + I)-(Paddle.X + PADDLE_SIZE / 2 + I, Paddle.Y + I), _RGB32(255)
    Next I
    Line (Paddle.X - PADDLE_SIZE / 2 - 3, Paddle.Y + 4)-(Paddle.X + PADDLE_SIZE / 2 + 3, Paddle.Y + 4), _RGB32(255)
End Sub

Function GetRandomColour&
    Select Case Int(Rnd * 4)
        Case 0: GetRandomColour = &HFFFBBC05
        Case 1: GetRandomColour = &HFF4285F4
        Case 2: GetRandomColour = &HFFEA4335
        Case 3: GetRandomColour = &HFF34A853
    End Select
End Function

'$Include:'max.bm'
'$Include:'min.bm'
'$Include:'iif.bm'
'$Include:'clamp.bm'
'$Include:'inrange.bm'
'$Include:'vector.bm'
