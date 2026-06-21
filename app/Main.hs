module Main where

import Brick
import Graphics.Vty as Vty (Event(EvKey), Key(KChar, KEsc), defAttr) 
import Mechanics (GameState, initialState)
import UI (drawGrid)


-- Recebe o evento atual e decide o que fazer com o Estado na Mónada de Eventos.
handleEvent :: BrickEvent () e -> EventM () GameState ()
handleEvent (VtyEvent e) = case e of
    Vty.EvKey (Vty.KChar 'q') [] -> halt
    Vty.EvKey Vty.KEsc        [] -> halt
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
