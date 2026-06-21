{-# LANGUAGE TemplateHaskell #-}
module Mechanics where

import Lens.Micro.TH (makeLenses)    

type Coord = (Int, Int)

data GameState = GameState {
    _liveCells  :: [Coord],
    _gamePaused :: Bool,
    _width      :: Int,
    _height     :: Int
}

makeLenses ''GameState

initialState :: GameState
initialState = GameState {
    _liveCells  = [],
    _gamePaused = True,
    _width      = 50,
    _height     = 30
}