/*
Author:
Nicholas Clark (SENSEI)
__________________________________________________________________*/
#include "script_component.hpp"

PREINIT;

PREP(init);
PREP(initSettings);
PREP(handleArea);
PREP(setArea);
PREP(setGarrison);
PREP(setOutpost);
PREP(setComm);
PREP(setTask);
PREP(getName);
PREP(removeArea);
PREP(spawnArea);
PREP(spawnGarrison);
PREP(spawnOutpost);
PREP(spawnPrefab);
PREP(spawnUnit);
PREP(taskOPORD);

// headless client exit 
if (!isServer) exitWith {};

GVAR(score) = 0;
GVAR(aliasBlacklist) = [];
GVAR(intelPrimary) = [];
GVAR(intelSecondary) = [];

SETTINGS_INIT;
