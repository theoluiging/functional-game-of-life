module Main where

import Brick
import Lens.Micro.Mtl ( (%=) )
import Graphics.Vty as Vty (
    Event(EvKey), 
    Key(KChar, KEsc, KUp, KDown, KLeft, KRight), 
    defAttr) 
import Mechanics
import UI (drawGrid)


-- Recebe o evento atual e decide o que fazer com o Estado na Mónada de Eventos.
handleEvent :: BrickEvent () e -> EventM () GameState ()
handleEvent (VtyEvent e) = case e of
    Vty.EvKey (Vty.KChar 'q') [] -> halt
    Vty.EvKey Vty.KEsc        [] -> halt
    Vty.EvKey Vty.KUp         [] -> do
        cursorPos %= \c -> moveCursor c U
        modify limitCursor
    Vty.EvKey Vty.KDown       [] -> do
        cursorPos %= \c -> moveCursor c D
        modify limitCursor
    Vty.EvKey Vty.KLeft       [] -> do
        cursorPos %= \c -> moveCursor c L
        modify limitCursor
    Vty.EvKey Vty.KRight      [] -> do
        cursorPos %= \c -> moveCursor c R
        modify limitCursor
handleEvent _ = return () -- Para qualquer outra tecla, não faz nada


app :: App GameState e ()
app = App { appDraw         = \st -> [drawGrid st]
          , appChooseCursor = neverShowCursor
          , appHandleEvent  = handleEvent
          , appStartEvent   = return ()
          , appAttrMap      = const $ attrMap defAttr []
          }


main :: IO ()
main = do
    _ <- defaultMain app initialState
    return ()
