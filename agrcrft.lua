
SLOT_CROPS = 1
SLOT_ANALYSER = 2
SLOT_SEEDS = 3

ACTIVATOR_PULSE_DURATION = 0.85

-- Interval at which the turtle checks if a plant has matured (in seconds)
MATURE_SLEEP_DURATION = 5
SPREAD_SLEEP_DURATION = 5
ANALYSE_SLEEP_DURATION = 1 -- interval for which to check if analyse process is finsished

-- If "true", excess non-10/10/10 seeds will get trashed
TRASH_EXCESS_SEEDS = true

-- the seed analyser uses absolute facing directions, adjust these depending on your setup
ANALYSER_LOWER_FACE = "EAST"
ANALYSER_UPPER_FACE = "WEST"

STATE_NORMAL = "normal"
STATE_ALTERNATE = "alternate" 

CROP_LOWER_RIGHT = { x = 2, y = 1 }
CROP_LOWER_LEFT = { x = 1, y = 1 }
CROP_UPPER_RIGHT = { x = 2, y = 2 }
CROP_UPPER_LEFT = { x = 1, y = 2 }

ANALYSER_LOWER_RIGHT = { x = 2, y = 0 }
ANALYSER_LOWER_LEFT = { x = 1, y = 0 }
ANALYSER_UPPER_RIGHT = { x = 2, y = 3 }
ANALYSER_UPPER_LEFT = { x = 1, y = 3 }

ACTIVATOR_LOWER_RIGHT = { x = 3, y = 1 }
ACTIVATOR_LOWER_LEFT = { x = 0, y = 1 }
ACTIVATOR_UPPER_RIGHT = { x = 3, y = 2 }
ACTIVATOR_UPPER_LEFT = { x = 0, y = 2 }

ANALYSER_MAIN = { x = 2, y = -1 }
CHEST = { x = 1, y = -1 }
TRASH = { x = 3, y = -1 }

LOWER_RIGHT = {
  crop = CROP_LOWER_RIGHT,
  analyser = ANALYSER_LOWER_RIGHT,
  analyserFace = ANALYSER_LOWER_FACE,
  activator = ACTIVATOR_LOWER_RIGHT
}

LOWER_LEFT = {
  crop = CROP_LOWER_LEFT,
  analyser = ANALYSER_LOWER_LEFT,
  analyserFace = ANALYSER_LOWER_FACE,
  activator = ACTIVATOR_LOWER_LEFT
}

UPPER_RIGHT = {
  crop = CROP_UPPER_RIGHT,
  analyser = ANALYSER_UPPER_RIGHT,
  analyserFace = ANALYSER_UPPER_FACE,
  activator = ACTIVATOR_UPPER_RIGHT
}

UPPER_LEFT = {
  crop = CROP_UPPER_LEFT,
  analyser = ANALYSER_UPPER_LEFT,
  analyserFace = ANALYSER_UPPER_FACE,
  activator = ACTIVATOR_UPPER_LEFT
}

POS_Y = 1
POS_X = 2
NEG_Y = 3
NEG_X = 4

currentFace = POS_Y
currentPos = { x = 1, y = -1 } -- same as the chest
currentState = STATE_NORMAL

STATES = {
  normal = { LOWER_RIGHT, UPPER_LEFT },
  alternate = { LOWER_LEFT, UPPER_RIGHT }
}

--
-- State management
--
function flipCurrentState()
  if currentState == STATE_NORMAL then
    currentState = STATE_ALTERNATE
  else
    currentState = STATE_NORMAL
  end
end

function currentField1()
  return STATES[currentState][1]
end

function currentField2()
  return STATES[currentState][2]
end

function oppositeState()
  return currentState == STATE_NORMAL and STATE_ALTERNATE or STATE_NORMAL
end

function oppositeField1()
  return STATES[oppositeState()][1]
end

function oppositeField2()
  return STATES[oppositeState()][2]
end

--
-- Movement and orientation
--
function turnLeft()
  turtle.turnLeft()
  currentFace = currentFace - 1
  if currentFace < POS_Y then
    currentFace = NEG_X
  end
end

function turnRight()
  turtle.turnRight()
  currentFace = currentFace + 1
  if currentFace > NEG_X then
    currentFace = POS_Y
  end
end

function turnToFace(face)
  local diff = currentFace - face
  if diff == 0 then
    return
  end

  if math.abs(diff) == 2 then
    turnLeft()
    turnLeft()
  elseif diff == 1 or diff == -3 then
    turnLeft()
  elseif diff == -1 or diff == 3 then
    turnRight()
  else
    error("Invalid difference: " + diff)
  end
end

function moveForward(times)
  while times > 0 do
    turtle.forward()
    adjustCurrentPos()
    times = times - 1
  end
end

function adjustCurrentPos()
  if currentFace == POS_Y then
    currentPos.y = currentPos.y + 1
  elseif currentFace == POS_X then
    currentPos.x = currentPos.x + 1
  elseif currentFace == NEG_Y then
    currentPos.y = currentPos.y - 1
  elseif currentFace == NEG_X then
    currentPos.x = currentPos.x - 1
  else
    error("Invald face: " + currentFace)
  end
end

function moveTo(pos)
  local diffx = currentPos.x - pos.x
  local diffy = currentPos.y - pos.y
  local facex = diffx > 0 and NEG_X or POS_X
  local facey = diffy > 0 and NEG_Y or POS_Y
  local absx = math.abs(diffx)
  local absy = math.abs(diffy)

  if currentFace == facex then
    moveForward(absx)
    if absy > 0 then
      turnToFace(facey)
      moveForward(absy)
    end
  elseif currentFace == facey then
    moveForward(absy)
    if absx > 0 then
      turnToFace(facex)
      moveForward(absx)
    end
  else
    if absx > 0 then
      turnToFace(facex)
      moveForward(absx)
    end
    if absy > 0 then
      turnToFace(facey)
      moveForward(absy)
    end
  end
end

--
-- Planting
--

function placeCropAndSeed(field)
  moveTo(field.crop)
  placeSingleCrop()
  moveTo(field.activator)
  placeSeed()
end

function placeCropAndCrossCrop(field)
  moveTo(field.crop)
  placeSingleCrop()
  moveTo(field.activator)
  placeCrossCrop()
end

function placeSingleCrop()
  turtle.select(SLOT_CROPS)
  turtle.placeDown()
end

function placeViaActivator(slot)
  turtle.select(slot)
  turtle.dropDown(1)

  rs.setOutput("bottom", true)
  os.sleep(ACTIVATOR_PULSE_DURATION)
  rs.setOutput("bottom", false)
end

function placeCrossCrop()
  placeViaActivator(SLOT_CROPS)
end

function placeSeed()
  placeViaActivator(SLOT_SEEDS)
end

function placeAnalyser()
  turtle.select(SLOT_ANALYSER)
  turtle.placeDown()

  return peripheral.wrap("bottom")
end

function waitForPlantToMature(face)
  analyser = placeAnalyser()
  while not analyser.isMature(face) do
    sleep(MATURE_SLEEP_DURATION)
  end

  turtle.digDown()
end

function waitForPlantToSpread(face)
  analyser = placeAnalyser()
  while not analyser.hasPlant(face) do
    sleep(SPREAD_SLEEP_DURATION)
  end

  turtle.digDown()
end

function waitForMaturePlant(field)
  moveTo(field.analyser)
  waitForPlantToMature(field.analyserFace)
end

function waitForSpread(field)
  moveTo(field.analyser)
  waitForPlantToSpread(field.analyserFace)
end

function harvest(field)
  moveTo(field.crop)
  turtle.select(SLOT_CROPS)
  turtle.digDown()
end

-- true if item at slot i should get dumped
-- returns true for everything that doesnt contain the word "seed" in the technical name
function dumpItem(i)
  local item = turtle.getItemDetail(i)
  if item == nil then
    return false
  end

  return string.find(string.lower(item.name), "seed") == nil
end

-- dumps all items that are not seeds into chest below, also returns slot numbers for the 2 collected seeds
function dumpHarvest()
  moveTo(CHEST)

  local s1 = nil
  local s2 = nil

  for i=3,16 do
    if dumpItem(i) then
      turtle.select(i)
      turtle.dropDown()
    elseif turtle.getItemDetail(i) ~= nil then
      if s1 == nil then
        s1 = i
      else
        s2 = i
      end
    end
  end
  return s1, s2
end

function analyseSlotGetStats(slot)
  analyser = placeAnalyser()
  turtle.select(slot)
  turtle.dropDown()
  analyser.analyze()

  while not analyser.isAnalyzed() do
    sleep(ANALYSER_SLEEP_DURATION)
  end

  gr, ga, str = analyser.getSpecimenStats()

  turtle.suckDown()
  turtle.select(SLOT_ANALYSER)
  turtle.digDown()

  return ((gr + ga + str) == 30)
end


function analyseSlotAndStore(slot)
  if slot == nil then
    return false
  end

  moveTo(ANALYSER_MAIN)
  local has30 = analyseSlotGetStats(slot)

  if has30 then
    moveTo(CHEST)
  else
    moveTo(TRASH)
  end

  turtle.select(slot)
  turtle.dropDown()
  return has30
end

function analyseHarvest(s1, s2)
  local s1Has30 = analyseSlotAndStore(s1)
  local s2Has30 = analyseSlotAndStore(s2)

  return s1Has30 or s2Has30
end

function main()
  placeCropAndSeed(currentField1())
  placeCropAndSeed(currentField2())

  local finishedBreeding = false

  while not finishedBreeding do
    waitForMaturePlant(currentField1())
    waitForMaturePlant(currentField2())

    placeCropAndCrossCrop(oppositeField1())
    placeCropAndCrossCrop(oppositeField2())

    waitForSpread(oppositeField1())
    waitForSpread(oppositeField2())

    harvest(currentField1())
    harvest(currentField2())

    s1, s2 = dumpHarvest()
    finishedBreeding = analyseHarvest(s1, s2)

    flipCurrentState()
  end

  -- harvest remaining 2 and store them
  harvest(currentField1())
  harvest(currentField2())
  s1, s2 = dumpHarvest()
  analyseHarvest(s1, s2)

  -- reset position
  moveTo(CHEST)
  turnToFace(POS_Y)
end

main()