'                     Google Breakout Clone
'                      by Aaditya Parashar
'
' Just Press F5... You have 3 balls to lose
'                  You will get more balls when you reach level 5

'$Dynamic
'$Include:'vector.bi'

Randomize Timer

Const BALL_RADIUS = 10
Const BUBBLE_RADIUS = 7
Const INITIAL_BALL_SPEED = 500
Const PADDLE_SIZE = 100

Const AI = 0
Const AI_PADDLE_SPEED = 10
Const GAME_SOUND = 1
Const FPS = 60
Const MOUSE_SENSITIVITY = 1 ' Ratio
Const KEYBOARD_SENSITIVITY = 10 ' Ratio

Const BRICK_SIZE_X = 40
Const BRICK_SIZE_Y = 15
Const STARTER_BRICKS = 8

'----- Don't Change -----
Const PADDLE_ERROR = PADDLE_SIZE / 10

Const MAX_LENGTH_OF_SOUND = 4
Const SOUND_BALL_BOUNCE = 1
Const SOUND_BRICK_COLLIDE = 2
Const SOUND_BALL_LOSE = 3
Const SOUND_NEW_LEVEL = 4
Const SOUND_LOSE = 5
'------------------------
Const MAX_POWER_UPS = 4

Type Ball
    As Vec2 Position
    As Vec2 Velocity, oldVelocity
    As Long IMAGE
    As _Unsigned Integer BrickCount
End Type
Type Brick
    As Vec2 Position, FinalPosition
    As _Unsigned _Byte Alive, Power
    As Long Colour
End Type
Type PowerUp
    As Vec2 Position
    As _Unsigned _Byte Power
End Type

Dim Shared As _Unsigned Integer NewScreenX, NewScreenY, NewScreenHeight
NewScreenHeight = 540
Screen _NewImage(960, NewScreenHeight, 32)
Color -1, _RGB32(0, 127)
'_FullScreen _SquarePixels , _Smooth
_Title "Breakout"
_MouseHide

Dim Shared TOTAL_BRICKS As _Unsigned Integer: TOTAL_BRICKS = STARTER_BRICKS
Dim Shared Balls(0) As Ball
Dim Shared As _Unsigned Integer TOTAL_BALLS, BACKUP_BALLS, MOVING_BALLS, MAX_BALL_SPEED, SLOW_BALL_SPEED: MAX_BALL_SPEED = INITIAL_BALL_SPEED
Dim Shared As _Unsigned Integer WIDTH, HALF_WIDTH, HEIGHT, HALF_HEIGHT
Dim As _Unsigned Integer Temporary_Ball_Speed
Dim Shared Level As _Unsigned Integer, LevelText$
Dim Shared Paddle As Vec2, New_Paddle_Size
Dim Shared As Brick Bricks(0), AI_Target_Brick

Dim Shared Available_Powers$
Dim Shared PowerUps(0 To 255) As PowerUp, CurrentPowerUps(0 To 255)

Dim Shared As Vec2 ParticlesPosition(0 To 255), ParticlesVelocity(0 To 255)
Dim Shared As Long ParticlesColour(0 To 255)

Paddle.X = _Width / 2
Paddle.Y = 530

BACKUP_BALLS = 3
CreateBall
Dim Shared As _Unsigned _Byte LevelShowTimer
NewLevel

Dim Shared As _Unsigned Long Score, BricksComboCount

Do
    _Limit FPS
    Cls , _RGB32(15)
    If _WindowHasFocus = 0 Then _Continue
    If _Height <> NewScreenHeight Then
        NewScreenX = _ScreenX
        NewScreenY = _ScreenY - (Level Mod 2)
        Screen _NewImage(_Width, _Height + Sgn(NewScreenHeight - _Height), 32)
        _ScreenMove NewScreenX, NewScreenY
    End If
    While _MouseInput
        Paddle.X = Clamp(New_Paddle_Size / 2, Paddle.X + _MouseMovementX * MOUSE_SENSITIVITY, _Width - New_Paddle_Size / 2)
        _MouseMove _Width / 2, _Height / 2
    Wend
    Paddle.X = Clamp(New_Paddle_Size / 2, Paddle.X + (_KeyDown(19200) - _KeyDown(19712)) * KEYBOARD_SENSITIVITY, _Width - New_Paddle_Size / 2)
    If CurrentPowerUps(3) > 0 And _MouseButton(2) And Timer(0.1) - BulletShootTimer > 1 - Level / 20 Then BulletShootTimer = Timer(0.1): Bullet Paddle.X - New_Paddle_Size / 2 + 10, Paddle.Y: Bullet Paddle.X + New_Paddle_Size / 2 - 10, Paddle.Y
    MOVING_BALLS = 0
    WIDTH = _Width
    HALF_WIDTH = WIDTH / 2
    HEIGHT = _Height
    HALF_HEIGHT = HEIGHT / 2

    For B = LBound(Balls) To UBound(Balls)
        If Vec2Length(Balls(B).Velocity) = 0 Then
            NewVec2 Balls(B).Position, Paddle.X, Paddle.Y - BALL_RADIUS
            If _MouseButton(1) Or _KeyDown(32) Then NewVec2 Balls(B).Velocity, Rnd - .5, -1
        End If
        If Abs(Balls(B).Velocity.X) > Abs(Balls(B).Velocity.Y) Then Swap Balls(B).Velocity.X, Balls(B).Velocity.Y
        MOVING_BALLS = MOVING_BALLS + Sgn(Vec2Length(Balls(B).Velocity))
        Temporary_Ball_Speed = IIF(CurrentPowerUps(2) > 0 And Balls(B).Velocity.Y > 0 And Balls(B).Position.Y > HALF_HEIGHT, SLOW_BALL_SPEED, MAX_BALL_SPEED)
        If Vec2Length(Balls(B).Velocity) Then
            Vec2Multiply Balls(B).Velocity, Temporary_Ball_Speed / Vec2Length(Balls(B).Velocity)
            Vec2MultiplyAdd Balls(B).Position, Balls(B).Velocity, 1 / FPS
        End If
        'Simulate Ball Boundary Collision
        Balls(B).Velocity.X = IIF(Balls(B).Position.X > _Width - BALL_RADIUS And Balls(B).Velocity.X > 0, -Balls(B).Velocity.X, Balls(B).Velocity.X)
        Balls(B).Velocity.X = IIF(Balls(B).Position.X < BALL_RADIUS And Balls(B).Velocity.X < 0, -Balls(B).Velocity.X, Balls(B).Velocity.X)
        Balls(B).Velocity.Y = IIF(Balls(B).Position.Y < BALL_RADIUS And Balls(B).Velocity.Y < 0, -Balls(B).Velocity.Y, Balls(B).Velocity.Y)
        If Balls(B).Position.Y > _Height - BALL_RADIUS And Balls(B).Velocity.Y > 0 Then KillBall B: Exit For
        '--------------------------------
        'Simulate Ball Paddle Collision
        If InRange(Paddle.X - New_Paddle_Size / 2 - PADDLE_ERROR, Balls(B).Position.X, Paddle.X + New_Paddle_Size / 2 + PADDLE_ERROR) And Balls(B).Position.Y + Balls(B).Velocity.Y / FPS + BALL_RADIUS > Paddle.Y And Balls(B).Velocity.Y > 0 Then
            Balls(B).Velocity.Y = -Balls(B).Velocity.Y
            Balls(B).Velocity.X = 10 * (Balls(B).Position.X - Paddle.X)
            BricksComboCount = 0
            If CurrentPowerUps(3) Then Bullet Paddle.X - New_Paddle_Size / 2 + 10, Paddle.Y: Bullet Paddle.X + New_Paddle_Size / 2 - 10, Paddle.Y
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
            BreakBrick I
            BricksComboCount = BricksComboCount + 1
            Balls(B).BrickCount = Balls(B).BrickCount + 1
            Score = Score + 5 * TOTAL_BALLS * BricksComboCount
            Score = Score - 5 * (COLLISION_FROM_TOP Or COLLISION_FROM_BOTTOM Or COLLISION_FROM_LEFT Or COLLISION_FROM_RIGHT)
            If Bricks(I).Alive Then
                AI_Target_Brick = Bricks(I)
            End If
        Next I
        '-----------------------------
        If BRICKS_COUNT = 0 Then
            PlaySound SOUND_NEW_LEVEL
            NewLevel
        End If
        If Vec2RoundEqual(Balls(B).Velocity, Balls(B).oldVelocity) = 0 Then
            Balls(B).oldVelocity = Balls(B).Velocity
            PlaySound SOUND_BALL_BOUNCE
            T = New_Paddle_Size * (Rnd - 0.5) / 2
        End If
        If AI Then
            dX = Balls(B).Position.X - Paddle.X + T
            If Balls(B).Position.Y > _Height * 0.8 Then Paddle.X = Paddle.X + Sgn(dX) * Min(Abs(dX), AI_PADDLE_SPEED)
        End If
    Next B

    DrawBricks
    DrawBalls
    DrawBackupBalls
    DrawPaddle
    DrawPowerUps
    PlaySound 0
    Particles 0, 0, 0
    Power 0, 0, 0
    Bullet 0, 0
    Bubble

    Print "FPS: "; __FPS
    Print "Score:"; Score
    If BricksComboCount > 1 Then
        CenterPrint "Combo x" + _Trim$(Str$(BricksComboCount)) + " (" + _Trim$(Str$(5 * TOTAL_BALLS * SumTo(BricksComboCount, 1))) + ")", 1
    End If
    If LevelShowTimer < 180 Then
        CenterPrint "Level" + Str$(Level), 0
        LevelShowTimer = LevelShowTimer + Sgn(255 - LevelShowTimer)
    End If
    _PrintString (_Width / 2 - _FontWidth * Len(LevelText$) / 2, 0), LevelText$
    _Display

    If BACKUP_BALLS + TOTAL_BALLS = 0 Then
        _AutoDisplay
        _MouseShow
        PlaySound SOUND_LOSE
        CenterPrint "You Lose", -1
        CenterPrint "Score" + Str$(Score), 0
        For I = 1 To MAX_LENGTH_OF_SOUND
            PlaySound 0
        Next I
        Sleep 1
        CenterPrint "Play Again (Y/N)?", 2
        Sleep
        If _KeyDown(89) Or _KeyDown(121) Then Run Else Exit Do
    ElseIf TOTAL_BALLS = 0 Then
        CreateBall
        BACKUP_BALLS = BACKUP_BALLS - 1
    End If
    LFPSCount = LFPSCount + 1
    If Timer(0.01) - oldTimer! > 1 Then
        oldTimer! = Timer(0.01)
        __FPS = LFPSCount
        LFPSCount = 0
    End If
Loop Until Inp(&H60) = 1
System

Function SumTo~& (X As _Unsigned Integer, S As _Unsigned Integer)
    For __I~& = 1 To X Step S
        __SUM~& = __SUM~& + __I~&
    Next __I~&
    SumTo~& = __SUM~&
End Function

Sub CenterPrint (T$, N)
    _PrintString (_Width / 2 - Len(T$) * _FontWidth / 2, _Height / 2 + _FontHeight * (N - 0.5)), T$
End Sub

Sub PlaySound (C As _Unsigned _Byte)
    Static As _Unsigned _Byte lC, O
    If (C And O = MAX_LENGTH_OF_SOUND) Or lC < C Then
        lC = C
        O = 1
    End If
    If GAME_SOUND = 0 Then Exit Sub
    Select Case lC
        Case SOUND_BALL_BOUNCE
            Select Case O
                Case 1: Sound 300, 1
            End Select
        Case SOUND_BRICK_COLLIDE
            Select Case O
                Case 1: Sound 400, 1
            End Select
        Case SOUND_BALL_LOSE
            Select Case O
                Case 1: Sound 250, 1
                Case 2: Sound 200, 1
            End Select
        Case SOUND_NEW_LEVEL
            Select Case O
                Case 1: Sound 400, 1
                Case 2: Sound 500, 1
            End Select
        Case SOUND_LOSE
            Select Case O
                Case 1: Sound 500, 1
                Case 2: Sound 400, 1
                Case 3: Sound 300, 1
                Case 4: Sound 200, 1
            End Select
    End Select
    O = O + Sgn(MAX_LENGTH_OF_SOUND - O)
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
            NewVec2 ParticlesVelocity(O), Rnd * 200 - 100, -Rnd * 100
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
            If InRange(Paddle.X - New_Paddle_Size / 2, ParticlesPosition(I).X, Paddle.X + New_Paddle_Size / 2) And ParticlesPosition(I).Y + BALL_RADIUS > Paddle.Y And ParticlesVelocity(I).Y > 0 Then
                ParticlesVelocity(I).Y = -ParticlesVelocity(I).Y
                ParticlesVelocity(I).X = 10 * (ParticlesPosition(I).X - Paddle.X)
            End If
            Line (ParticlesPosition(I).X - BRICK_SIZE_X / 20, ParticlesPosition(I).Y - BRICK_SIZE_Y / 20)-(ParticlesPosition(I).X + BRICK_SIZE_X / 20, ParticlesPosition(I).Y + BRICK_SIZE_Y / 20), ParticlesColour(I), BF
        End If
    Next I
End Sub

Sub Bubble
    Static Bubbles(0 To 255) As Vec2, BubblesState(0 To 255) As _Unsigned _Byte
    Static LastBubbleTimer As Single, NewBubble As _Unsigned _Byte
    For I = 0 To 255
        Circle (Bubbles(I).X, Bubbles(I).Y), BUBBLE_RADIUS, _RGB32(255, 128 - Abs(BubblesState(I) - 128))
        BubblesState(I) = BubblesState(I) + Sgn(BubblesState(I))
        Bubbles(I).X = Bubbles(I).X + 0.25
        Bubbles(I).Y = Bubbles(I).Y - 0.20
    Next I
    If CurrentPowerUps(2) And Timer(0.1) - LastBubbleTimer > 1 Then
        LastBubbleTimer = Timer(0.01)
        Bubbles(NewBubble).X = Rnd * _Width
        Bubbles(NewBubble).Y = (0.6 + Rnd * 0.4) * _Height
        BubblesState(NewBubble) = 1
        NewBubble = NewBubble + 1
    End If
End Sub

Sub Bullet (X As Integer, Y As Integer)
    Static Bullets(0 To 255) As Vec2
    Static As _Unsigned _Byte BulletID, BulletsAlive(0 To 31), Brick_Collided
    Dim As _Unsigned Integer I, J
    If X Or Y Then
        Bullets(BulletID).X = X
        Bullets(BulletID).Y = Y
        BulletsAlive(_SHR(BulletID, 3)) = _SetBit(BulletsAlive(_SHR(BulletID, 3)), BulletID And 7)
        BulletID = BulletID + 1
    End If
    For I = 0 To 255
        If _ReadBit(BulletsAlive(_SHR(I, 3)), I And 7) = 0 Then _Continue
        Bullets(I).Y = Bullets(I).Y - 10
        Brick_Collided = 0
        For J = LBound(Bricks) To UBound(Bricks)
            If Bricks(J).Alive And InRange(-BRICK_SIZE_X / 2, Bullets(I).X - Bricks(J).Position.X, BRICK_SIZE_X / 2) And InRange(-BRICK_SIZE_Y / 2, Bullets(I).Y - Bricks(J).Position.Y, BRICK_SIZE_Y) Then Brick_Collided = J
        Next J
        Line (Bullets(I).X - 1, Bullets(I).Y - 7)-(Bullets(I).X + 1, Bullets(I).Y + 1), -1, BF
        If Bullets(I).Y > 0 And Brick_Collided = 0 Then _Continue
        BulletsAlive(_SHR(I, 3)) = _ResetBit(BulletsAlive(_SHR(I, 3)), I And 7)
        If Brick_Collided Then Bricks(Brick_Collided).Alive = 0: BreakBrick Brick_Collided
    Next I
End Sub

Sub Power (X As Integer, Y As Integer, P As _Unsigned _Byte)
    Static As _Unsigned _Byte O
    If X Or Y Then
        NewVec2 PowerUps(O).Position, X, Y
        PowerUps(O).Power = P
        O = O + 1
    End If
    For I = 0 To 255
        Select Case PowerUps(I).Power
            Case 0
            Case 1: ApplyPowerUp PowerUps(I): PowerUps(I).Power = 0
            Case Else: PowerUps(I).Position.Y = PowerUps(I).Position.Y + 4
                If InRange(Paddle.X - New_Paddle_Size / 2, PowerUps(I).Position.X, Paddle.X + New_Paddle_Size / 2) And PowerUps(I).Position.Y + BALL_RADIUS > Paddle.Y Then
                    ApplyPowerUp PowerUps(I)
                    PowerUps(I).Power = 0
                End If
        End Select
        Select Case I
            Case 2 To 4: CurrentPowerUps(I) = CurrentPowerUps(I) - Sgn(CurrentPowerUps(I)) * Sgn(MOVING_BALLS)
        End Select
    Next I
End Sub
Sub ApplyPowerUp (P As PowerUp)
    Select Case P.Power
        Case 1: CurrentPowerUps(1) = CurrentPowerUps(1) + 1 'Increment Balls
            CreateBall
            Balls(UBound(Balls)).Position = P.Position
            NewVec2 Balls(UBound(Balls)).Velocity, Rnd - 0.5, Rnd - 0.5
        Case 2 To 4: CurrentPowerUps(P.Power) = 10 * FPS 'Set 10 Seconds
    End Select
End Sub

Sub NewLevel
    ReDim Bricks(0) As Brick
    For I = 1 To TOTAL_BRICKS
        CreateBrick
    Next I
    MAX_BALL_SPEED = MAX_BALL_SPEED + IIF(Level < 10, 50, IIF(Level < 20, 25, IIF(Level < 50, 10, 5)))
    SLOW_BALL_SPEED = 0.6 * MAX_BALL_SPEED
    Level = Level + 1: LevelText$ = "Level" + Str$(Level)
    _Title "Breakout - Level" + Str$(Level): LevelShowTimer = 0
    TOTAL_BRICKS = Min(TOTAL_BRICKS + 8, 64)
    BACKUP_BALLS = BACKUP_BALLS + IIF(Level >= 5, 1, 0)
    If (Level Mod 2) = 0 And Len(Available_Powers$) < MAX_POWER_UPS Then Available_Powers$ = Available_Powers$ + Chr$(Len(Available_Powers$) + 1)
    If (Level Mod 5) = 0 Then NewScreenHeight = _Height + 60
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
    PlaySound SOUND_BALL_LOSE
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
    If Rnd > 0.9 And Len(Available_Powers$) Then Bricks(BrickID).Power = Asc(Available_Powers$, 1 + Int(Rnd * Len(Available_Powers$)))
    X = X + 1
    If X = 0 Then Y = Y + 1
End Sub
Sub BreakBrick (I As _Unsigned Integer)
    Bricks(I).Alive = 0
    Particles Bricks(I).Position.X, Bricks(I).Position.Y, Bricks(I).Colour
    PlaySound SOUND_BRICK_COLLIDE
    Power Bricks(I).Position.X, Bricks(I).Position.Y, Bricks(I).Power
End Sub
Sub DrawBricks
    For I = LBound(Bricks) To UBound(Bricks)
        If Bricks(I).Alive = 0 Then _Continue
        Line (Bricks(I).Position.X - BRICK_SIZE_X / 2, Bricks(I).Position.Y - BRICK_SIZE_Y / 2)-(Bricks(I).Position.X + BRICK_SIZE_X / 2, Bricks(I).Position.Y + BRICK_SIZE_Y / 2), Bricks(I).Colour, BF
        dX = Bricks(I).FinalPosition.X - Bricks(I).Position.X
        dY = Bricks(I).FinalPosition.Y - Bricks(I).Position.Y
        Bricks(I).Position.X = Bricks(I).Position.X + Sgn(dX)
        Bricks(I).Position.Y = Bricks(I).Position.Y + Sgn(dY)
        If Bricks(I).Power > 0 Then _PrintString (Bricks(I).Position.X - _FontWidth / 2, Bricks(I).Position.Y - _FontHeight / 2), _Trim$(Str$(Bricks(I).Power))
    Next I
End Sub
Sub DrawBalls
    For I = LBound(Balls) To UBound(Balls)
        If I <= 0 Then _Continue
        _PutImage (Balls(I).Position.X - BALL_RADIUS, Balls(I).Position.Y - BALL_RADIUS)-(Balls(I).Position.X + BALL_RADIUS, Balls(I).Position.Y + BALL_RADIUS), Balls(I).IMAGE
        If CurrentPowerUps(2) And Balls(I).Position.Y > _Height / 2 Then
            Circle (Balls(I).Position.X, Balls(I).Position.Y), BALL_RADIUS + 2, -1
            Circle (Balls(I).Position.X, Balls(I).Position.Y), BALL_RADIUS + 3, -1
        End If
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
    Static LaserPosition
    New_Paddle_Size = SmoothTransit(New_Paddle_Size, PADDLE_SIZE + 100 * Sgn(CurrentPowerUps(4)), 2)
    For I = 0 To 3
        Line (Paddle.X - New_Paddle_Size / 2 - I, Paddle.Y + I)-(Paddle.X + New_Paddle_Size / 2 + I, Paddle.Y + I), _RGB32(255)
    Next I
    Line (Paddle.X - New_Paddle_Size / 2 - 3, Paddle.Y + 4)-(Paddle.X + New_Paddle_Size / 2 + 3, Paddle.Y + 4), _RGB32(255)
    If CurrentPowerUps(3) Then
        NewLaserPosition = -4
    Else
        NewLaserPosition = 0
    End If
    LaserPosition = LaserPosition + Sgn(NewLaserPosition - LaserPosition)
    Line (Paddle.X - New_Paddle_Size / 2 + 10, Paddle.Y + LaserPosition)-(Paddle.X - New_Paddle_Size / 2 + 10, Paddle.Y + LaserPosition + 4), -1, BF
    Line (Paddle.X - New_Paddle_Size / 2 + 9, Paddle.Y + LaserPosition + 1)-(Paddle.X - New_Paddle_Size / 2 + 9, Paddle.Y + LaserPosition + 4), -1, BF
    Line (Paddle.X + New_Paddle_Size / 2 - 10, Paddle.Y + LaserPosition)-(Paddle.X + New_Paddle_Size / 2 - 10, Paddle.Y + LaserPosition + 4), -1, BF
    Line (Paddle.X + New_Paddle_Size / 2 - 9, Paddle.Y + LaserPosition + 1)-(Paddle.X + New_Paddle_Size / 2 - 9, Paddle.Y + LaserPosition + 4), -1, BF
End Sub
Sub DrawPowerUps
    Static C&(0 To 255)
    If C&(0) = 0 Then
        For I = 0 To 255: C&(I) = GetRandomColour: Next I
    End If
    For I = 0 To 255
        If PowerUps(I).Power = 0 Then _Continue
        Line (PowerUps(I).Position.X - 10, PowerUps(I).Position.Y - 10)-(PowerUps(I).Position.X + 9, PowerUps(I).Position.Y + 9), C&(I), BF
    Next I
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
'$Include:'smoothtransit.bm'
