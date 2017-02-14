/*
Author:
Nicholas Clark (SENSEI)

Description:
secondary task - find intel 02

Arguments:
0: forced task position <ARRAY>

Return:
none
__________________________________________________________________*/
#define TASK_SECONDARY
#define TASK_NAME 'Find Map Intel'
#define INTEL_CLASS QUOTE(ItemMap)
#define INTEL_CONTAINER GVAR(DOUBLES(intel02,container))
#define UNITCOUNT 8
#include "script_component.hpp"

params [
    ["_position",[],[[]]]
];

// CREATE TASK
_taskID = str diag_tickTime;
_classes = [];
_cleanup = [];
INTEL_CONTAINER = objNull;

if (_position isEqualTo []) then {
	_position = [EGVAR(main,center),EGVAR(main,range),"house"] call EFUNC(main,findPosTerrain);
};

if (_position isEqualTo []) exitWith {
	TASK_EXIT_DELAY(0);
};

_position = _position select 1;

call {
	if (EGVAR(main,enemySide) isEqualTo EAST) exitWith {
		_classes = EGVAR(main,vehPoolEast);
	};
	if (EGVAR(main,enemySide) isEqualTo WEST) exitWith {
		_classes = EGVAR(main,vehPoolWest);
	};
	if (EGVAR(main,enemySide) isEqualTo RESISTANCE) exitWith {
		_classes = EGVAR(main,vehPoolInd);
	};
};

_grp = [_position,0,UNITCOUNT,EGVAR(main,enemySide),false,TASK_SPAWN_DELAY] call EFUNC(main,spawnGroup);

[
	{count units (_this select 0) >= UNITCOUNT},
	{
		params ["_grp","_cleanup"];

        _cleanup append (units _grp);
        removeFromRemainsCollector units _grp;

		{
			removeAllAssignedItems _x;
			removeHeadgear _x;
            removeVest _x;
		} forEach (units _grp);

        {
            leader _grp removeItemFromUniform _x;
        } forEach (uniformItems leader _grp);

        INTEL_CONTAINER = [leader _grp,INTEL_CLASS] call FUNC(addItem);

        // regroup patrols
        [
            _grp,
            2,
            {[_this select 0, _this select 0, 30, 5, "MOVE", "SAFE", "YELLOW", "LIMITED", "STAG COLUMN", "", [0,5,8]] spawn CBA_fnc_taskPatrol}
        ] call EFUNC(main,splitGroup);
	},
	[_grp,_cleanup]
] call CBA_fnc_waitUntilAndExecute;

TASK_DEBUG(_position);

// SET TASK
_taskDescription = "Aerial reconnaissance spotted an enemy fireteam patrolling a nearby settlement. Ambush the unit and search the enemy combatants for intel.";
[true,_taskID,[_taskDescription,TASK_TITLE,""],_position,false,true,"search"] call EFUNC(main,setTask);

// PUBLISH TASK
TASK_PUBLISH(_position);

// TASK HANDLER
[{
    params ["_args","_idPFH"];
    _args params ["_taskID","_grp","_cleanup"];

    if (TASK_GVAR isEqualTo []) exitWith {
        [_idPFH] call CBA_fnc_removePerFrameHandler;
        [_taskID, "CANCELED"] call EFUNC(main,setTaskState);
        _cleanup call EFUNC(main,cleanup);
        TASK_EXIT_DELAY(30);
    };

    if (!isNull INTEL_CONTAINER && {{COMPARE_STR(INTEL_CLASS,_x)} count itemCargo INTEL_CONTAINER < 1}) exitWith {
        [_idPFH] call CBA_fnc_removePerFrameHandler;
        [_taskID, "SUCCEEDED"] call EFUNC(main,setTaskState);
        TASK_APPROVAL(getPos (leader _grp),TASK_AV);
        _cleanup call EFUNC(main,cleanup);
        TASK_EXIT;
    };
}, TASK_SLEEP, [_taskID,_grp,_cleanup]] call CBA_fnc_addPerFrameHandler;
