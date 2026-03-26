%% Dot Objects
nYScreens = 2;
nYScreens_objects = nYScreens + 2;
nObjects = 10*nYScreens_objects;
ObjectPos = rand(nObjects,2).*[screenXpixels, nYScreens_objects*screenYpixels];
ObjectColor = [1 1 0]*white;
ObjectSize = 10;
speed = 0.1/nYScreens;
breakLoop = false;

CollectedScore = 0;

%% Player Ship
ShipSpeed = 4/nYScreens;
ShipDir = 0;
ShipSize = 50;
ShipLoc = [screenXpixels/2-ShipSize/2 screenYpixels-100-ShipSize ...
    screenXpixels/2+ShipSize/2 screenYpixels-100];

%% Obstacles

GratingHolderSize = 310;
ShipXlim = [GratingHolderSize screenXpixels - GratingHolderSize];

nObstacles = 2*nYScreens;
ObstacleColor = [1 0 0]*white;
ObstacleSize = 100;
ObstacleSpeed = 0.1/nYScreens * 7;
ObstaclePos = rand(nObstacles,2).*[screenXpixels - 1.5*GratingHolderSize, nYScreens*screenYpixels] ...
    + [0.75*GratingHolderSize - 0.5*ObstacleSize, 0];

%% Enemy Ships
nEnemyShips = 0.5*nYScreens;
EnemyShipColor = [1 0 1]*white;
EnemyShipSize = 50;
EnemyShipSpeed = 1/nYScreens * 7;
EnemyShipPos = rand(nEnemyShips,2).*[screenXpixels - 1.5*GratingHolderSize, nYScreens*screenYpixels] ...
    + [0.75*GratingHolderSize - 0.5*EnemyShipSize, 0];
