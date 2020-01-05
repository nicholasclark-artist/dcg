/*
Author:
Nicholas Clark (SENSEI)

Description:
set outpost locations

Arguments:

Return:
bool
__________________________________________________________________*/
#include "script_component.hpp"
#define SCOPE QGVAR(setOutpost)

// define scope to break hash loop
scopeName SCOPE;

private ["_outposts","_pos","_polygonPositions","_terrain","_location"];

_outposts = [];

[GVAR(areas),{
    // exit when outpost count reached
    if (count _outposts isEqualTo OP_COUNT) then {
        breakTo SCOPE;
    };

    _pos = [];
    _polygonPositions = [];
    _terrain = "";

    // get random positions in polygon
    for "_i" from 0 to 4 do {
        _polygonPositions pushBack ([_value getVariable [QEGVAR(main,polygon),[]]] call EFUNC(main,polygonRandomPos));
    };
    
    // find position based on terrain type
    { 
        private _terrainKVP = selectRandom [["meadow",50],["peak",20],["forest",20]];
        _pos = [_x,500,_terrainKVP select 0,0,0,_terrainKVP select 1,true] call EFUNC(main,findPosTerrain);

        // exit when position found
        if !(_pos isEqualTo []) exitWith {
            _terrain = _terrainKVP select 0;
        }; 
    } forEach _polygonPositions;

    if (!(_pos isEqualTo []) && {_pos inPolygon (_value getVariable [QEGVAR(main,polygon),[]])}) then { 
        // create outpost location
        _location = createLocation ["Invisible",ASLtoAGL _pos,1,1];

        // @todo fix water positions 
        TRACE_3("",_key,_terrain,_pos);
        
        // setvars
        _location setVariable [QGVAR(active),1];
        _location setVariable [QGVAR(type),"outpost"];
        _location setVariable [QGVAR(name),call FUNC(getName)]; 
        _location setVariable [QGVAR(task),""];
        _location setVariable [QGVAR(composition),[]];
        _location setVariable [QGVAR(nodes),[]];
        _location setVariable [QGVAR(terrain),_terrain];
        _location setVariable [QGVAR(positionASL),_pos];
        _location setVariable [QGVAR(radius),0]; // will be adjusted based on composition size
        _location setVariable [QGVAR(groups),[]]; // groups assigned to outpost
        _location setVariable [QGVAR(unitCountCurrent),0]; // actual unit count
        _location setVariable [QGVAR(onKilled),{ // update unit count on killed event
            _this setVariable [QGVAR(unitCountCurrent),(_this getVariable [QGVAR(unitCountCurrent),-1]) - 1];
        }];

        // setup hash
        _outposts pushBack [_key,_location];

        // update score
        [QGVAR(updateScore),[_value,OP_SCORE]] call CBA_fnc_localEvent;
    };
}] call CBA_fnc_hashEachPair;

// create outpost hash
GVAR(outposts) = [_outposts,locationNull] call CBA_fnc_hashCreate;

(count ([GVAR(outposts)] call CBA_fnc_hashKeys)) > 0