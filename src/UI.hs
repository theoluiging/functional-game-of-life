module UI where

import Brick.Widgets.Core (str, hBox, vBox)
import Brick.Widgets.Border (borderWithLabel, border)
import Brick.Types (Widget)
import Lens.Micro ((^.))
import Mechanics (GameState, liveCells, width, height, cursorPos)

drawGrid:: GameState -> Widget n
drawGrid st = vBox linhas 
    where
        linhas = [ drawLine y width st | y <- [0 .. height-1] ]

drawLine:: Int -> Int -> GameState -> Widget n
drawLine y w st = hBox [ drawCell (x, y) st | x <- [0 .. w-1] ]

drawCell:: (Int, Int) -> GameState -> Widget n
drawCell coord st = 
    if coord == (st ^. cursorPos) then 
            if elem coord (st ^. liveCells) then 
                str "[]"
            else 
                str "><"
    else if elem coord (st ^. liveCells) then 
        str "██"
    else 
        str "  "

drawMenu:: Widget n
drawMenu = border (hBox [str "[R] Restart  ", str "[SPACE] Toggle Cell  ", str "[ENTER] Start/Stop  ", str "[Q] Exit "])

drawUI:: GameState -> Widget n
drawUI st = vBox [borderedGrid st, drawMenu]
    where
        borderedGrid = borderWithLabel (str "Conway's Game of Life") . drawGrid
