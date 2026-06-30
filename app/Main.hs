module Main where

import Brick
import Lens.Micro.Mtl ( (%=), use, (.=) )
import Graphics.Vty as Vty (
    Event(EvKey), 
    Key(KChar, KEsc, KUp, KDown, KLeft, KRight, KEnter), 
    defAttr) 
import Mechanics
import UI (drawUI)

handleMoveEvent :: Mechanics.Direction -> EventM () GameState ()
handleMoveEvent dir = do
    cursorPos %= \c -> moveCursor c dir
    modify limitCursor

-- Recebe o evento atual e decide o que fazer com o Estado na Mónada de Eventos.
handleEvent :: BrickEvent () e -> EventM () GameState ()
handleEvent (VtyEvent e) = case e of
    Vty.EvKey (Vty.KChar 'q') [] -> halt
    Vty.EvKey Vty.KEsc        [] -> halt
    Vty.EvKey Vty.KUp         [] -> handleMoveEvent U
    Vty.EvKey (Vty.KChar 'w') [] -> handleMoveEvent U
    Vty.EvKey Vty.KDown       [] -> handleMoveEvent D
    Vty.EvKey (Vty.KChar 's') [] -> handleMoveEvent D
    Vty.EvKey Vty.KLeft       [] -> handleMoveEvent L
    Vty.EvKey (Vty.KChar 'a') [] -> handleMoveEvent L
    Vty.EvKey Vty.KRight      [] -> handleMoveEvent R
    Vty.EvKey (Vty.KChar 'd') [] -> handleMoveEvent R
    Vty.EvKey (Vty.KChar 'r') [] -> liveCells .= []
    Vty.EvKey (Vty.KChar ' ') [] -> do
        c <- use cursorPos
        liveCells %= toggleCell c
    _ -> return ()
handleEvent _ = return () -- Para qualquer outra tecla, não faz nada


app :: App GameState e ()
app = App { appDraw         = \st -> [drawUI st]
          , appChooseCursor = neverShowCursor
          , appHandleEvent  = handleEvent
          , appStartEvent   = return ()
          , appAttrMap      = const $ attrMap defAttr []
          }


main :: IO ()
main = do
    _ <- defaultMain app initialState
    return ()
