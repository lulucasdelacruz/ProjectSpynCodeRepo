USINGSIM = false;

% check if brick exists in the workspace that way we don't get an error
if exist('brick', 'var') == 0

    % If it doesn't we create the brick with the respective create methods.
    if USINGSIM
        addpath('C:\Program Files\MATLAB\R2021b\toolbox\EV3');
        javaclasspath('C:\Program Files\MATLAB\R2021b\toolbox\EV3');
        brick = Brick('ioType','wifi','wfAddr','127.0.0.1','wfPort',5555,'wfSN','0016533dbaf5');
    else
        brick = ConnectBrick("WINNERS");
    end
    disp("Created new brick instance successfully.")
end

% Setting motors and sensor ports to variables to be easily changed
LEFTMOTOR = 'A';
RIGHTMOTOR = 'D';
PICKUPMOTOR = 'C';
GYRO = 1;
LEFTTOUCHSENSOR = 2;
RIGHTTOUCHSENSOR = 3;
COLORSENSOR = 4;

% Setting universal speed controls and motor power adjustment variables and
% error settings
FORWARDSPEED = 50;
BACKUPSPEED = 30;
LEFTMOTORPOWERADJUST = 100;
RIGHTMOTORPOWERADJUST = 100;
TURNINGSPEED = 10;
MARIGINOFTURNERROR = 2;
PICKUPSPEED = 5;
PICKUPMOTORDOWNPOSITION = brick.GetMotorAngle(PICKUPMOTOR);
PICKUPMOTORUPPOSITION = PICKUPMOTORDOWNPOSITION + 45;

% Variables that will be used for the code to tell where the robot is
HasHandicapPerson = false;
LastHitWallTime = datetime('now') - seconds(30.0);
LastTimeWentOverRed = datetime('now') - seconds(30.0);
DroppedOff = false;

% Initialize robot sensors
brick.SetColorMode(COLORSENSOR, 2);
brick.GyroCalibrate(GYRO);
pause(2);

% Start running the robot. Reset pickup arm and run the robot straight
% ahead.
brick.MoveMotorAngleAbs(PICKUPMOTOR, PICKUPSPEED, PICKUPMOTORDOWNPOSITION);
brick.MoveMotor(LEFTMOTOR, FORWARDSPEED);
brick.MoveMotor(RIGHTMOTOR, FORWARDSPEED);

while true
    % Compensates for motor drift and ensures robot is running straight
    % ahead.
    ContinueStraightOrBackwards(brick, LEFTMOTOR, RIGHTMOTOR, GYRO, FORWARDSPEED, 1);

    % Check if we are hitting a wall, and if we are, we update the last
    % time we hit a wall.
    LastHitWallTime = CheckIfHittingWall(brick, LastHitWallTime, LEFTMOTOR, RIGHTMOTOR, GYRO, FORWARDSPEED, BACKUPSPEED, LEFTTOUCHSENSOR, RIGHTTOUCHSENSOR, MARIGINOFTURNERROR, TURNINGSPEED);
    
    % Check if we are going over the color red, and if we are, we update
    % the last time we went over red.
    LastTimeWentOverRed = CheckIfInRedArea(brick, LastTimeWentOverRed, LEFTMOTOR, RIGHTMOTOR, FORWARDSPEED, COLORSENSOR);
    
    % Check if we are in a blue area, and if we are, we note that we have
    % the person.
    HasHandicapPerson = CheckIfInBlueArea(brick, HasHandicapPerson, GYRO, MARIGINOFTURNERROR, LEFTMOTOR, RIGHTMOTOR, FORWARDSPEED, TURNINGSPEED, PICKUPMOTOR, PICKUPSPEED, PICKUPMOTORUPPOSITION, PICKUPMOTORDOWNPOSITION, COLORSENSOR);
    
    % Check if we are in a green area, and if we are, we note that we
    % dropped off the person.
    DroppedOff = CheckIfInGreenArea(brick, DroppedOff, HasHandicapPerson, LEFTMOTOR, RIGHTMOTOR, BACKUPSPEED, PICKUPMOTOR, PICKUPSPEED, PICKUPMOTORDOWNPOSITION, COLORSENSOR);
    
    % If we have dropped the person, we break out of the while true
    % statement to terminate the program.
    if DroppedOff
        break;
    end
end

function DroppedOff = CheckIfInGreenArea(brick, DroppedOff, HasHandicapPerson, LEFTMOTOR, RIGHTMOTOR, BACKUPSPEED, PICKUPMOTOR, PICKUPSPEED, PICKUPMOTORDOWNPOSITION, COLORSENSOR)
    
    % Check if the color sensor is reading green
    if (brick.ColorCode(COLORSENSOR) == 3)

        % Stop the motors and wait a second for them to fully stop moving
        brick.StopAllMotors();
        pause(1);

        % Put the handicap person down and wait and then terminate the code
        % by setting dropped off to true. (Terminates the main while loop)
        brick.MoveMotorAngleAbs(PICKUPMOTOR, PICKUPSPEED, PICKUPMOTORDOWNPOSITION);
        pause(1);
        DroppedOff = true;
    end
end

function HasHandicapPerson = CheckIfInBlueArea(brick, HasHandicapPerson, GYRO, MARIGINOFTURNERROR, LEFTMOTOR, RIGHTMOTOR, FORWARDSPEED, TURNINGSPEED, PICKUPMOTOR, PICKUPSPEED, PICKUPMOTORUPPOSITION, PICKUPMOTORDOWNPOSITION, COLORSENSOR)
    % If we already have the person, we dont want to enable keyboard
    % controls again
    if HasHandicapPerson
        return;
    end
    
    % Check and see if the ground is blue
    if (brick.ColorCode(COLORSENSOR) == 2)
        % Stop all motors so we can take over
        brick.StopAllMotors();
        
        % Create global key and keyboard so we can control robot
        global key
        InitKeyboard();
        
        % Create a loop that we will break out of with q once we have the
        % person secured
        while true
            % pause inbetween key pressed so that we can ensure we go at
            % least a little bit forward
            pause(0.1);
            switch key
                % Go forwards
                case 'w'
                    brick.MoveMotor(LEFTMOTOR, FORWARDSPEED);
                    brick.MoveMotor(RIGHTMOTOR, FORWARDSPEED);

                % Turn right
                case 'a'
                    brick.MoveMotor(LEFTMOTOR, TURNINGSPEED * -1);
                    brick.MoveMotor(RIGHTMOTOR, TURNINGSPEED);

                % Back up
                case 's'
                    brick.MoveMotor(LEFTMOTOR, FORWARDSPEED * -1);
                    brick.MoveMotor(RIGHTMOTOR, FORWARDSPEED * -1);

                % Turn left
                case 'd'
                    brick.MoveMotor(LEFTMOTOR, TURNINGSPEED);
                    brick.MoveMotor(RIGHTMOTOR, TURNINGSPEED * -1);

                % Lift the Person up off the ground
                case 'uparrow'
                    brick.MoveMotorAngleAbs(PICKUPMOTOR, PICKUPSPEED, PICKUPMOTORUPPOSITION);
                    pause(1);
                
                % Put our lifting mechanism down on the ground
                case 'downarrow'
                    brick.MoveMotorAngleAbs(PICKUPMOTOR, PICKUPSPEED, PICKUPMOTORDOWNPOSITION);
                    pause(1);
                
                % Stop all motors when no key is being pressed
                case 0
                    brick.StopAllMotors();

                % Exit the loop once we get the handicap person
                case 'q'
                    brick.GyroCalibrate(GYRO);
                    disp("Quitting keyboard control. Returning to algorithm.")
                    break;

                % Tape sometimes reads as blue so this will act as an
                % escape function to prevent accidental reports.
                case 'r'
                    return;
            end
        end
        
        % Let us know we have the handicap person. Used in blue area and in
        % drop off area to ensure we have the person.
        HasHandicapPerson = true;
        
%         % First zero out our position and then continue going straight.
%         FaceAngle(0, brick, GYRO, LEFTMOTOR, RIGHTMOTOR, TURNINGSPEED, MARIGINOFTURNERROR);
%         brick.MoveMotor(LEFTMOTOR, FORWARDSPEED);
%         brick.MoveMotor(RIGHTMOTOR, FORWARDSPEED);
    end
end

function LastTimeWentOverRed = CheckIfInRedArea(brick, LastTimeWentOverRed, LEFTMOTOR, RIGHTMOTOR, FORWARDSPEED, COLORSENSOR)
    
    % Check to see if the color the color sensor reading is red
    if (brick.ColorCode(COLORSENSOR) == 5)

        % Checks to see if we went over red within 10 seconds. This makes
        % sure we don't just get stuck running and pausing over the
        % readline after we waited 5 seconds.
        if (seconds(datetime('now') - LastTimeWentOverRed) > 10)
            % Update the time we last went over red
            LastTimeWentOverRed = datetime('now');

            % Stop motors and wait for 5 seconds
            brick.StopAllMotors();
            pause(5);

            % 5 seconds are up so we should move forward again
            brick.MoveMotor(LEFTMOTOR, FORWARDSPEED);
            brick.MoveMotor(RIGHTMOTOR, FORWARDSPEED);
        end
    end
end

function LastHitWallTime = CheckIfHittingWall(brick, LastHitWallTime, LEFTMOTOR, RIGHTMOTOR, GYRO, FORWARDSPEED, BACKWARDSPEED, LEFTTOUCHSENSOR, RIGHTTOUCHSENSOR, MARIGINOFTURNERROR, TURNINGSPEED)

    % Check and see if either of the touch sensors are being pressed down
    if (brick.TouchPressed(LEFTTOUCHSENSOR) || brick.TouchPressed(RIGHTTOUCHSENSOR))

        while (~brick.TouchPressed(LEFTTOUCHSENSOR) || ~brick.TouchPressed(RIGHTTOUCHSENSOR))
            brick.MoveMotor(LEFTMOTOR, FORWARDSPEED);
            brick.MoveMotor(RIGHTMOTOR, FORWARDSPEED);
        end

        brick.StopAllMotors();

        pause(2);
        brick.GyroCalibrate(GYRO);

        % Back up from the wall
        brick.StopAllMotors();
        brick.MoveMotor(LEFTMOTOR, BACKWARDSPEED * -1);
        brick.MoveMotor(RIGHTMOTOR, BACKWARDSPEED * -1);
        
        % back up for 1.5 seconds while making sure we are going straight
        % back.
        start = datetime('now');
        while seconds(datetime('now') - start) < 1.5
            ContinueStraightOrBackwards(brick, LEFTMOTOR, RIGHTMOTOR, GYRO, BACKWARDSPEED, -1);
        end

        % Stop motors
        brick.StopAllMotors();

        disp("Time from last hit: " + (seconds(datetime('now') - LastHitWallTime)) + " seconds");

        % Check and see if we hit another wall within 5 seconds. If we did,
        % we will do a full 180 degree spin to turn around. If we didn't we
        % will rotate -90 degrees to turn left.
        if (seconds(datetime('now') - LastHitWallTime) < 6)
            FaceAngle(180, brick, GYRO, LEFTMOTOR, RIGHTMOTOR, TURNINGSPEED, MARIGINOFTURNERROR);
        else
            FaceAngle(-90, brick, GYRO, LEFTMOTOR, RIGHTMOTOR, TURNINGSPEED, MARIGINOFTURNERROR);
        end

        % Zero out the gyro since we just made a turn
        brick.GyroCalibrate(GYRO);

        % Continue straight once again
        brick.MoveMotor(LEFTMOTOR, FORWARDSPEED);
        brick.MoveMotor(RIGHTMOTOR, FORWARDSPEED);

        % Update the time we last hit a wall
        LastHitWallTime = datetime('now');
    end
end

function ContinueStraightOrBackwards(brick, LEFTMOTOR, RIGHTMOTOR, GYRO, FORWARDSPEED, FORWARDORBACKWARD)
    % Get our corrent offset so we know what our correction value should be
    Offset = brick.GyroAngle(GYRO);

    % Multiply our offset by -1.45. Found the value by just running the
    % code and seeing what made it run completely straight
    correction = Offset * -1.45;
    
    % If we are going backwards we need to subtract from left and add to
    % right since we are going the opposite direction and if we are going
    % forwards, we need to add to left and subtract from right.
    if FORWARDORBACKWARD == -1
        LEFTMOTORPOWERADJUST = FORWARDSPEED - correction;
        RIGHTMOTORPOWERADJUST = FORWARDSPEED + correction;
    else 
        LEFTMOTORPOWERADJUST = FORWARDSPEED + correction;
        RIGHTMOTORPOWERADJUST = FORWARDSPEED - correction;
    end
    
    % Finally adjust the motor speed using move motor
    brick.MoveMotor(LEFTMOTOR, LEFTMOTORPOWERADJUST * FORWARDORBACKWARD);
    brick.MoveMotor(RIGHTMOTOR, RIGHTMOTORPOWERADJUST * FORWARDORBACKWARD);

    % Print for debugging purposes
    disp("Offset: " + Offset + " Correction: " + correction + " LEFTMOTORSPEED: " + LEFTMOTORPOWERADJUST + " RIGHTMOTORSPEED:" + RIGHTMOTORPOWERADJUST); 
end

function FaceAngle(Angle, brick, GYRO, LEFTMOTOR, RIGHTMOTOR, TURNINGSPEED, MARIGINOFTURNERROR)
    % Create variable with filler value;
    % This will be used to check and see if the correction has been the
    % same 2 times a row meaning the robot is stuck
    PreviousCorrection = 100000;

    while true
        Offset = Angle - brick.GyroAngle(GYRO);

        % For some reason the initial value is sometimes NaN the first time
        % the loop runs. This just sets a value so it doesn't break the
        % rest of the code.
        if isnan(Offset)
            Offset = Angle;
        end

        % This will check and see if the target angle is hit within the
        % margin of error. If it is, the code will go ahead and return.
        if abs(Offset) <= MARIGINOFTURNERROR
            brick.StopAllMotors();

            % Pauses for 6 seconds to allow the robot to stop spinning
            pause(6);

            % Check once again to make sure the target goal is met after it
            % has stopped spinning completely
            if abs(Offset) <= MARIGINOFTURNERROR
                break;
            end
        end
       
        % Correction value tells the brick how many degrees it should turn
        correction = Offset * -1;

        % Check and see if the correction values are the same. If they are,
        % we know the robot is stuck and needs to have its correction
        % increased to try and free it.
        if correction == PreviousCorrection
            correction = correction * 2;
        end
        PreviousCorrection = correction;
    
        % Tell the robot to turn
        brick.MoveMotorAngleRel(LEFTMOTOR, TURNINGSPEED, correction * -1); brick.MoveMotorAngleRel(RIGHTMOTOR, TURNINGSPEED, correction);

        % Debug output
        disp("Angle: " + brick.GyroAngle(GYRO) + " Correction: " + correction + " Offset: " + Offset);

        % Pause to let the motors spin
        pause(1.5);
    end
    disp("Successfully turned " + brick.GyroAngle(GYRO));
end