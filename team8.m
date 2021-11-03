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

% brick = ConnectBrick("WINNERS");

brick.SetColorMode(1, 4);
brick.MoveMotor('A', 50);
brick.MoveMotor('B', 50); 

while (true)
    disp(brick.ColorCode(1));
    if (brick.ColorCode(1) == 5)
        break;
    end
end

stopAllMotors(brick);

pause(3);

brick.MoveMotor('A', 50);
brick.MoveMotor('B', 50); 

while (true)
    disp(brick.UltrasonicDist(2));
    if (brick.UltrasonicDist(2) <= 30)
        break;
    end
end

stopAllMotors(brick);

pause(3);

% Makes Robot Turn Right
brick.MoveMotor('A', 50);
brick.MoveMotor('B', -50);

pause(2);

stopAllMotors(brick);

function stopAllMotors(Brick)
    Brick.StopMotor('A');
    Brick.StopMotor('B');
end
