import Brick.*;
import bluetooth.*;
import wfBrickIO.*;
import usbBrickIO.*;
import keyboard.*;
import colorSensor.*;
import ConnectBrick.*;

% addpath('C:\Program Files\MATLAB\R2021b\toolbox\EV3');
% javaclasspath('C:\Program Files\MATLAB\R2021b\toolbox\EV3');

% brick = Brick('ioType','wifi','wfAddr','127.0.0.1','wfPort',5555,'wfSN','0016533dbaf5');

brick = ConnectBrick("WINNERS");
brick.SetColorMode(1, 4);
run(brick);


function run(brick)
    lastHitRed = datetime('now') - seconds(10.0);
    goStraight(brick);
    while (true)
        lastHitRed = hitsRed(brick, lastHitRed);
    end
end

function newTimeHit = hitsRed(brick, lastHitRed)
    newTimeHit = lastHitRed;
    if (brick.ColorCode(1) == 5)
        if (seconds(datetime('now') - lastHitRed) > 10)
            newTimeHit = datetime('now');
            stopAllMotors(brick);
            pause(5);
            goStraight(brick);
        end
    end
end

function hittingWall(brick)
    if (brick.TouchPressed(3))
        StopAllMotors(brick);
        turnRight()
    end
end

function goStraight(brick)
    brick.MoveMotor('A', 50);
    brick.MoveMotor('B', 50);
end

function stopAllMotors(brick)
    brick.StopMotor('A');
    brick.StopMotor('B');
end

function turnRight(brick)
    brick.MoveMotor('A', 50);
    brick.MoveMotor('B', -50);
end
