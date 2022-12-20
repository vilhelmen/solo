#!/usr/bin/env lua

local math = require "math"
local table = require "table"

math.randomseed(0) -- TODO: switch with appropriate playdate stuff, maybe a debug toggle as well

print("Deck init")

function build_deck()
	local singles = {'0'} -- multiply by color
	local doubles = {'1','2','3','4','5','6','7','8','9','D','R','S'} -- multiply by color by 2
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
for i = 1, 4 do
	table.insert(players,{hand={};id=i})
end

-- deal hands
for _ = 1,7 do
	for i = 1, #players do
		table.insert(players[i].hand, table.remove(deck))
	end
end
for i = 1, #players do
	table.sort(players[i].hand)
end


local turn = math.random(#players)
local order = 1 -- -1 for reverse


do
	-- make wilddraw an illegal first card
	local first = table.remove(deck)
	while first == 'Xz' do
		-- put it back, somewhere that is NOT the top, pls
		table.insert(deck, math.random(#deck - 1), first)
		first = table.remove(deck)
	end
	-- moving first card to top deck instead of top of discard
	-- this lets us play it using regular flow for rendering
	table.insert(deck, first)
end

-- UHHHHH stomp over the card code if it's wild and the color has been selected?
-- but then you need to remember to reset it
-- otherwise we need an external wild color tracker

function dump()
	print('TOD: ', discard[#discard])
	print('Current player: ', turn)
	print('Order: ', order)
	print('Hands: ')
	for i = 1, #players do
		print('', i, table.concat(players[i].hand, ','))
	end
end

function analyze()
	-- gather intel
	-- flag everyone near winning
	-- figure out which turn order is better
	-- figure out skip/draw/wild strats
	-- build hand plan?
	local intel = {}
	for i = 1, #players do
		table.inset(intel, {
			winning=#players[i].hand <= 4; -- 4 or 3????
			id=players[i].id;
			distance=0 -- idk how to compute this just yet
		}
	end
end

function run()
while true do
	
end
end


run()




if first[1] == 'S' then
	-- shift to 0-base, apply rotation, then shift back ;)
	turn = (((turn - 1) + order) % 4) + 1
elseif first[1] == 'R' then
	order = order * -1
end
