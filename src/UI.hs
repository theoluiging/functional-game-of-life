module UI where

import Brick.Widgets.Core (str, hBox, vBox)
import Brick.Types (Widget)
import Lens.Micro ((^.))
import Mechanics (GameState, liveCells, width, height)

drawGrid:: GameState -> Widget n
drawGrid st = vBox linhas 
    where
        w = st ^. width
        h = st ^. height
        linhas = [ drawLine y w st | y <- [0 .. h-1] ]

drawLine:: Int -> Int -> GameState -> Widget n
drawLine y w st = hBox [ drawCell (x, y) st | x <- [0 .. w-1] ]

drawCell:: (Int, Int) -> GameState -> Widget n
drawCell coord st = 
    if 
        elem coord (st ^. liveCells) then str "██"
    else 
        str "  "

