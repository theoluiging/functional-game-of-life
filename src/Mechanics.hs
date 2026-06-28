{-# LANGUAGE TemplateHaskell #-}
module Mechanics where

import Lens.Micro.TH (makeLenses)
import Lens.Micro ((^.))

type Coord = (Int, Int)

data Direction = U | D | L | R

data GameState = GameState {
    _liveCells  :: [Coord],
    _gamePaused :: Bool,
    _width      :: Int,
    _height     :: Int,
    _cursorPos  :: Coord
}

makeLenses ''GameState

initialState :: GameState
initialState = GameState {
    _liveCells  = [],
    _gamePaused = True,
    _width      = startWidth,
    _height     = startHeight,
    _cursorPos  = (startWidth `div` 2, startHeight `div` 2)
}

startWidth:: Int
startWidth = 50

startHeight:: Int
startHeight = 30

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
        w = st ^. width
        h = st ^. height
        newX = x `mod` w
        newY = y `mod` h