module Logic where

import Mechanics ( Coord, limitCoord )
import Data.List (nub)

-- Retorna a lista de vizinhos de um ponto, limitados pelo tamanho do tabuleiro
neighbors:: Coord -> [Coord]
neighbors (x,y) = [limitCoord (x + dx, y + dy) | dx <- [-1, 0, 1], dy <- [-1, 0, 1], (dx, dy) /= (0, 0)]

-- Recebe uma Coordenada alvo e a lista de Células Vivas, e devolve o número de vizinhos alives.
countNeighbors:: Coord -> [Coord] -> Int
countNeighbors target liveCells = length (filter (\x -> elem x liveCells) (neighbors target))

nextStep :: [Coord] -> [Coord]
nextStep liveCells = newCells
    where
        allNeighbors = concatMap neighbors liveCells
        
        -- Junta as células vivas com os vizinhos e remove os repetidos
        candidates = nub (liveCells ++ allNeighbors)

        -- Regras do Conway's Game of Life  
        mustLive :: Coord -> Bool
        mustLive c = 
            let aliveNeighbors = countNeighbors c liveCells
                isAlive = elem c liveCells
            in 
                if isAlive then
                    if aliveNeighbors < 2 then 
                        False -- Underpopulation
                    else if aliveNeighbors == 2 || aliveNeighbors == 3 then 
                        True -- Survival
                    else 
                        False -- Overpopulation
                else 
                    if aliveNeighbors == 3 then
                        True -- Reproduction
                    else
                        False

        newCells = filter mustLive candidates
