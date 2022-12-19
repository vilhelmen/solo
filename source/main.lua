#!/usr/bin/env lua

local math = require "math"
local table = require "table"

math.randomseed(0) -- TODO: switch with appropriate playdate stuff, maybe a debug toggle as well

print("Deck init")

function build_deck()
	local singles = {'0','S','R','D'} -- multiply by color
	local doubles = {'1','2','3','4','5','6','7','8','9'} -- multiply by color by 2
	local quads = {'W','X'} -- 4 of each, null color. I don't like X but I need something that comes after W
	local colors = {'r','y','g','b'} -- capitalization?
	-- this should make a reasonable ordering when sorted as well. Handy.
	-- Color should be added to the back for better planning, but should be reversed for user display maybe
	
	local deck = {} -- TODO: change to playdate table create func
	
	-- I have decided I do not like lua
	for _, pass_color in pairs(colors) do
		for _, v in pairs(singles) do
			table.insert(deck, v .. pass_color)
		end
		for _, v in pairs(doubles) do
			table.insert(deck, v .. pass_color)
			table.insert(deck, v .. pass_color)
		end
		for _, v in pairs(quads) do
			table.insert(deck, v .. 'z')
		end
	end
	return deck
end

function shuffle_deck(deck)
	-- lua is pass by ref so this makes calling a little ugly.
	-- Don't think there's a case where I should deepcopy or whatever
	-- UGH fisher-yates is FINE
	-- there's a notable tendency to swap with itself towards the end but whatever
	-- no point to iteration i=1 since it always self swaps
	local j
	for i = #deck, 2, -1 do
		j = math.random(i)
		deck[i], deck[j] = deck[j], deck[i]
	end
end

local deck = build_deck()
print(table.concat(deck,','))
shuffle_deck(deck)
print(table.concat(deck,','))

local discard = {} -- TODO: playdate table create
-- just setting it to 4 for now
local players = {} -- ^^
for i = 1,4 do
	table.insert(players,{hand={};})
end

-- how many are in a hand?
for _ = 1,7 do
	for i = 1, #players do
		table.insert(players[i].hand, table.remove(deck))
	end
end
for i = 1, #players do
	table.sort(players[i].hand)
end

table.insert(discard, table.remove(deck))

local turn = math.random(#players)
local order = 1 -- -1 for reverse

-- need to support initial wild (and therefore wilddraw)
-- OR... just secretly flip through the deck and swap it with the first normal card ;)
-- need to crossref some docs for esoteric edge cases

-- surely the 0 seed doesn't cause this problem and I can kick that can

print('TOD: ',discard[#discard])
print('Current player: ', turn)
print('Order: ', order)
print('Hands: ')
for i = 1,#players do
	print('', i, table.concat(players[i].hand,','))
end

-- how much of individual hand strat data can be cached between turns?
-- combos and non-normie cards are the only ones of real interest