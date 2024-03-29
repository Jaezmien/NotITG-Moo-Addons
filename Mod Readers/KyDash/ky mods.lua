--[==[
general timed mod/function arguments:
	mod
		{start, end, 'mods' [, pn, timing]} OR {start, 'mods' [, pn]}
	optional inputs
		- pn: can be a player number or a table of player numbers
			use negative players as a shorthandle for 'all players EXCEPT'
			defaults to all players
		- timing: sets the end type to either 'len' or 'end'
			defaults to 'len'
	example usage
		{2, 10, '*-1 100 drunk'}
			🡤 applies 100% drunk from beats 2 to 12
		{2, 10, '*-1 tipsy', pn = 1, timing = 'end'}
			🡤 applies 100% tipsy on player 1 from beats 2 to 10
		{5, '*-1 1000 zoomz', pn = {1, 4, 2}}
			🡤 applies 1000% zoomz for one frame on players 1, 2, and 4
		{0, '*-1 50 stealth', pn = -2}
			🡤 applies 50% stealth for one frame on all players except player 2
	ease mod
		{start, end, % start, % end, 'mod' [, ease, args, pn, timing, sustain, sustain_timing]} OR
		{start, end, 'mod', % start, % end, [, ease, args, pn, timing, sustain, sustain_timing]}
	notes
		only a single mod can be passed in with an ease mod
	optional inputs
		- ease: function that defines the curve being used for the mod
			normal format is function(time, begin, cchange, duration, ...)
			defaults to `linear`
		- args: additional arguments to pass to the ease function
		- timing: sets the end type to either 'len' or 'end'
			defaults to 'len'
		- pn: can be a player number or a table of player numbers
			use negative players as a shorthandle for 'all players EXCEPT'
			defaults to all players
		- sustain: number determining how long to hold a mod at it's final percentage after the ease has run
		- sustain_timing: sets sustain value to be either 'len' based (`end` + `sustain`) or 'end' based
			defaults to value of `timing`
	example usage
		{0, 4, 0, 500, 'drunk'}
			🡤 apply drunk from 0% to 100%, using a `linear` curve, from beats 0 to 4 
		{4, 4, 'reverse', 100, 0, ease = outBounce}
			🡤 apply reverse from 100% to 0%, using an `outBounce` curve, from beats 4 to 8 
		{0, 8, 'bumpy', 1000, -500, ease = inElastic, args = {0.5, 6}}
			🡤 apply bumpy from 100% to 0%, using an `inElastic` curve, while passing 0.5 and 6 as extra arguments, from beats 0 to 8
		{8, 12, 0, 10, 'tandrunk', ease = inOutQuad, pn = 2, timing = 'end'}
			🡤 apply tandrunk from 0% to 10% on player 2, using an `inOutQuad` curve, from beats 8 to 12
		{0, 1, 'rotationz', 0, 180, sustain = 10}
			🡤 apply rotationz from 0% to 180% from beats 0 to 1, and hold the value at 180% from beats 1 to 11
		{0, 1, 'rotationz', 0, 180, sustain = 8, sustain_timing = 'end'}
			🡤 apply rotationz from 0% to 180% from beats 0 to 1, and hold the value at 180% from beats 1 to 8
	function
		{start, function [, persist, timing, func_if_persist, func_args]}
	optional inputs
		- persist: can be a boolean or a number, specifying the range to run the function if playback is started after the starting point in the editor
		- timing: if using persist as a number, sets the range of beats the function will run to be either 'len' or 'end'
			defaults to 'len'
		- func_if_persist: if using persist, will run the function specified instead of the first function
		- func_args: can any value, or a table of values that will be passed into the function
	-- perframe
		{start, end, function [, timing, persist, persist_timing, func_if_persist, func_args]}
	-- ease function
		{start, end, function, start val, end val [, ease, args, timing, persist, persist_timing, func_if_persist, func_args]} OR
		{start, end, start val, end val, function [, ease, args, timing, persist, persist_timing, func_if_persist, func_args]}
how to use:
	preface your new entry with the keyword `mod` followed by it's arguments detailed above
		mod {0, 1, '*-1 50 drunk'}
	entries can be chained meaning that a following entry does not require `mod`
		mod {0, 1, '*-1 50 drunk'}
		{1, 20, '*10 beat', timing = 'end'}
		{0, 10, 'tipsy', 0, 100, ease = inOutCirc}
		{4, function() print('hi') end}
		etc, etc
]==]

local init_mods = '*-1 overhead, *-1 2x, *-1 zbuffer, approachtype'

-- no a() function

mod {0, 9E9, init_mods}

-- mod { 0, 9e9, '*-1 beat' }