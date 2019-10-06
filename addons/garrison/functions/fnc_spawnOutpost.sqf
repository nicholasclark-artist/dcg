/*
Author:
Nicholas Clark (SENSEI)

Description:
spawn outposts, should not be called directly

Arguments:

Return:
nothing
__________________________________________________________________*/
#include "script_component.hpp"
#define SCOPE QGVAR(spawnOutpost)
#define SPAWN_DELAY 0.5

// @todo fix garrison units not moving in combat 

// define scope to break hash loop
scopeName SCOPE;

[GVAR(outposts),{
    // get composition type
    private _type = (_value getVariable [QGVAR(terrain),""]) call {
        if (COMPARE_STR(_this,"meadow")) exitWith {"mil_cop"};
        if (COMPARE_STR(_this,"peak")) exitWith {"mil_pb"};
        if (COMPARE_STR(_this,"forest")) exitWith {"mil_pb"};

        ""
    };

    // get patrol unit count based on player count
    private _unitCount = [8,24] call EFUNC(main,getUnitCount);

    // simplify outpost position 
    private _posOutpost =+ (_value getVariable [QGVAR(positionASL),DEFAULT_SPAWNPOS]); 
    _posOutpost resize 2;

    // spawn outpost for certain terrain type
    private _composition = [_posOutpost,_type,random 360,true] call EFUNC(main,spawnComposition);
    
    if (_composition isEqualTo []) then {
        breakTo SCOPE;
    };

    // setvars 
    _value setVariable [QGVAR(composition),_composition select 2];
    _value setVariable [QGVAR(radius),_composition select 0];

    // spawn infantry patrol
    private _pos = [_posOutpost,(_composition select 0) + 10,(_composition select 0) + 50,2,0,-1,[0,360],_posOutpost getPos [(_composition select 0) + 20,random 360]] call EFUNC(main,findPosSafe);

    for "_i" from 1 to floor (_unitCount/OP_PATROLSIZE) do {
        private _grp = [_pos,0,OP_PATROLSIZE,EGVAR(main,enemySide),SPAWN_DELAY] call EFUNC(main,spawnGroup);

        [{(_this select 0) getVariable [QEGVAR(main,ready),false]},
            {
                params ["_grp","_location"];
                
                // add eventhandlers
                {
                    _x setVariable [QGVAR(location),_location];
                    _x addEventHandler ["Killed", {
                        _location = (_this select 0) getVariable [QGVAR(location),locationNull];
                        _location call (_location getVariable [QGVAR(onKilled),{}]);
                    }]; 
                } forEach (units _grp);

                [QGVAR(updateUnitCount),[_location,count units _grp]] call CBA_fnc_localEvent;
                [QGVAR(updateGroups),[_location,_grp]] call CBA_fnc_localEvent;

                // set group on patrol
                [_grp, getPos _location, (50 max (_location getVariable [QGVAR(radius),100])) * (random [1,2,3]), 4, "MOVE", "SAFE", "YELLOW", "LIMITED", "STAG COLUMN", "if (0.1 > random 1) then {this spawn CBA_fnc_searchNearby}", [5,16,15]] call CBA_fnc_taskPatrol;
            },
            [_grp,_value],
            (SPAWN_DELAY * _unitCount) * 2
        ] call CBA_fnc_waitUntilAndExecute;
    };
    
    // get composition buildings with suitable positions  
    private _buildings = _posOutpost nearObjects ["House", _composition select 0];
    _buildings = _buildings select {!((_x buildingPos -1) isEqualTo [])};
    
    if (_buildings isEqualTo []) then {
        WARNING_1("%1 outpost does not have building positions",_key);
    };

    // garrison officer
    private _officer = (createGroup EGVAR(main,enemySide)) createUnit [selectRandom ([EGVAR(main,enemySide),3] call EFUNC(main,getPool)), DEFAULT_SPAWNPOS, [], 0, "CAN_COLLIDE"];
    
    private _dir = random 360;
    _officer setFormDir _dir;
    _officer setDir _dir;
    
    if (_buildings isEqualTo []) then {
        _officer setPosASL ([_posOutpost,0,(_composition select 0) * 0.5,2,-1,-1,[0,360],[_posOutpost select 0,_posOutpost select 1,getTerrainHeightASL _posOutpost]] call EFUNC(main,findPosSafe));
    } else {
        _officer setPosATL selectRandom ((selectRandom _buildings) buildingPos -1);
    };

    // add eventhandlers and vars
    _value setVariable [QGVAR(officer),_officer];
    _officer setVariable [QGVAR(location),_value];
    _officer addEventHandler ["Killed", {
        _location = (_this select 0) getVariable [QGVAR(location),locationNull];
        _location call (_location getVariable [QGVAR(onKilled),{}]);
    }]; 

    [QEGVAR(cache,enableGroup),group _officer] call CBA_fnc_serverEvent;
    [QGVAR(updateUnitCount),[_value,1]] call CBA_fnc_localEvent;
    [QGVAR(updateGroups),[_value,group _officer]] call CBA_fnc_localEvent;

    // garrison infantry
    private ["_unit","_dir"];

    {
        if (PROBABILITY(0.5)) then {
            _unit = (createGroup EGVAR(main,enemySide)) createUnit [selectRandom ([EGVAR(main,enemySide),0] call EFUNC(main,getPool)), DEFAULT_SPAWNPOS, [], 0, "CAN_COLLIDE"];

            _dir = random 360;
            _unit setFormDir _dir;
            _unit setDir _dir;

            if (PROBABILITY(0.5)) then { // garrison building exit
                _unit setPosATL (_x buildingExit 0);
            } else { // garrison building position
                _unit setPosATL selectRandom (_x buildingPos -1);
            };

            // add eventhandlers
            _unit setVariable [QGVAR(location),_value];
            _unit addEventHandler ["Killed", {
                _location = (_this select 0) getVariable [QGVAR(location),locationNull];
                _location call (_location getVariable [QGVAR(onKilled),{}]);
            }]; 

            [QEGVAR(cache,enableGroup),group _unit] call CBA_fnc_serverEvent;
            [QGVAR(updateUnitCount),[_value,1]] call CBA_fnc_localEvent;
            [QGVAR(updateGroups),[_value,group _unit]] call CBA_fnc_localEvent;
        };
    } forEach _buildings;

    // spawn addition garrison units inside outpost (not at building positions)
    for "_i" from 0 to (floor ((_composition select 0) / 4) min 16) do {
        _pos = [_posOutpost,0,(_composition select 0) * 0.9,2,-1,-1,[0,360],_posOutpost] call EFUNC(main,findPosSafe);

        // avoid units stacking at outpost pivot
        if !(_pos isEqualTo _posOutpost) then {
            _unit = (createGroup EGVAR(main,enemySide)) createUnit [selectRandom ([EGVAR(main,enemySide),0] call EFUNC(main,getPool)), DEFAULT_SPAWNPOS, [], 0, "CAN_COLLIDE"];
            
            _dir = random 360;
            _unit setFormDir _dir;
            _unit setDir _dir;
            _unit setPosASL _pos;

            // add eventhandlers and vars
            _unit setVariable [QGVAR(location),_value];
            _unit addEventHandler ["Killed", {
                _location = (_this select 0) getVariable [QGVAR(location),locationNull];
                _location call (_location getVariable [QGVAR(onKilled),{}]);
            }]; 

            [QEGVAR(cache,enableGroup),group _unit] call CBA_fnc_serverEvent;
            [QGVAR(updateUnitCount),[_value,1]] call CBA_fnc_localEvent;
            [QGVAR(updateGroups),[_value,group _unit]] call CBA_fnc_localEvent;
        };
    };

    // @todo add comms array intel to officer 

    // check dynamic task params
    
    // spawn outpost task
    private _taskID = [_key,diag_frameNo] joinString "_";
    private _taskAO = [GVAR(areas),_key] call CBA_fnc_hashGet;
    private _taskNearest = _taskAO getVariable [QEGVAR(main,mapLocation),locationNull];
    private _taskSituationOrientation = [[(getPos _taskNearest) getDir (getPos _value)] call EFUNC(main,getDirCardinal),text _taskNearest] joinString " of ";

    // private _taskSituation = format ["Some time ago, a small group of enemy combatants was spotted constructing an outpost %1. The enemy force is composed of dismounted patrols and potentially, static emplacements. They are expected to defend upon contact.",_taskSituationOrientation];

    private _taskSituation = format ["Some time ago, a convoy of military logistics and engineering vehicles was spotted entering AO %1. These vehicles are likely supporting the construction of an enemy outpost (OBJ %2). Previous engagements have shown the enemy to be composed of dismounted patrols and potentially, static emplacements. They are expected to defend upon contact.",_taskAO getVariable [QGVAR(name),""],_value getVariable [QGVAR(name),""]];

    private _taskMission = format ["Friendly forces will conduct an operation in AO %1 to locate and secure OBJ %2 in order to prevent anti-coalition forces from gaining momentum and swaying civilian approval.",_taskAO getVariable [QGVAR(name),""], _value getVariable [QGVAR(name),""]];

    private _taskSustainment = ["","","","","Each Soldier will carry his/her full basic load.","","","All squads will maintain necessary medical equipment and will ensure it is replenished prior to each movement.","",""];

    _taskStr = [_value,_taskAO,_value getVariable [QGVAR(name),""],_taskAO getVariable [QGVAR(name),""],_value getVariable [QGVAR(terrain),""],_taskSituation,_taskMission,_taskSustainment] call EFUNC(main,taskOPORD);

    // [true,_taskID,[_taskStr select 1,_taskStr select 0,""],[_taskAO getVariable [QEGVAR(main,polygon),DEFAULT_POLYGON]] call EFUNC(main,polygonCentroid),"CREATED",0,true,"attack"] call BIS_fnc_taskCreate;

    [true,_taskID,[_taskStr select 1,_taskStr select 0,""],[objNull, getPos _value] select GVAR(enableMarkers),"CREATED",0,true,"attack"] call BIS_fnc_taskCreate;

    _value setVariable [QGVAR(task),_taskID];

    TRACE_2("outpost task",_key,_taskID);
}] call CBA_fnc_hashEachPair;

nil