{-# LANGUAGE TemplateHaskell #-}
module Mechanics where

import Lens.Micro.TH (makeLenses)
import Lens.Micro ((^.))

type Coord = (Int, Int)

data Direction = U | D | L | R

data GameState = GameState {
    _liveCells  :: [Coord],
    _gamePaused :: Bool,
    _cursorPos  :: Coord
}

width:: Int
width = 35

height:: Int
height = 25

makeLenses ''GameState

initialState :: GameState
initialState = GameState {
    _liveCells  = [],
    _gamePaused = True,
    _cursorPos  = (width `div` 2, height `div` 2)
}


moveCursor:: Coord -> Direction -> Coord
moveCursor (x,y) dir = case dir of
    U   -> (x, y - 1)
    D -> (x, y + 1)
    L -> (x - 1, y)
    R -> (x + 1, y)

limitCursor:: GameState -> GameState
limitCursor st = st {_cursorPos = (newX, newY)}
    where
        (x,y) = st ^. cursorPos
        newX = x `mod` width
        newY = y `mod` height

toggleCell:: Coord -> [Coord] -> [Coord]
toggleCell c cells =
    if elem c cells then
        filter (/= c) cells
    else
        c : cells
