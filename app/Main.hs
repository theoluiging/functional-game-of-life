module Main where

import Control.Concurrent (forkIO, threadDelay)
import Control.Monad (forever)

import Brick
import Brick.BChan (newBChan, writeBChan)

import Lens.Micro.Mtl ( (%=), use, (.=) )

import qualified Graphics.Vty as Vty
import qualified Graphics.Vty.CrossPlatform as VCP

import Mechanics
import UI (drawUI)
import Logic ( nextStep )


data Tick = Tick

handleMoveEvent :: Mechanics.Direction -> EventM () GameState ()
handleMoveEvent dir = do
    cursorPos %= \c -> moveCursor c dir
    modify limitCursor

handleNextState:: EventM () GameState ()
handleNextState = do
    liveCells %= nextStep
    modify limitCells

-- Recebe o evento atual e decide o que fazer com o Estado na Mónada de Eventos.
handleEvent :: BrickEvent () Tick -> EventM () GameState ()
handleEvent (AppEvent Tick) = do
    pausado <- use gamePaused
    if pausado
        then return () -- Se estiver pausado, não faz nada
        else do handleNextState
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
    Vty.EvKey (Vty.KChar 'r') [] -> do 
        liveCells .= []
        gamePaused .= True
    Vty.EvKey (Vty.KChar ' ') [] -> do
        c <- use cursorPos
        liveCells %= toggleCell c
    Vty.EvKey (Vty.KChar 't') [] -> handleNextState
    Vty.EvKey Vty.KEnter      [] -> gamePaused %= not
    _ -> return () -- Para qualquer outra tecla, não faz nada
handleEvent _ = return () 


app :: App GameState Tick ()
app = App { appDraw         = \st -> [drawUI st]
          , appChooseCursor = neverShowCursor
          , appHandleEvent  = handleEvent
          , appStartEvent   = return ()
          , appAttrMap      = const $ attrMap Vty.defAttr []
          }


main :: IO ()
main = do
    -- canal de comunicação do Brick que suporta até 10 mensagens na fila
    chan <- newBChan 10

    -- Metronomo em thread paralela
    _ <- forkIO $ forever $ do
        writeBChan chan Tick
        threadDelay 500000     -- 500,000 microssegundos (0.5 segundos)

    -- Configuração do customMain
    let buildVty = VCP.mkVty Vty.defaultConfig
    initialVty <- buildVty

    _ <- customMain initialVty buildVty (Just chan) app initialState
    
    return ()
