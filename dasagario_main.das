require daslib/media
require daslib/decs_boost

var RAND_SEED : int4

//do scene entity
var FREE_TEAM_ID : int = 0
let LOC_SIZE = 5000.f
let INIT_FOOD_COUNT = 1000
let BOTS_POP = 50
let START_MASS = 10.f
let MAX_START_MASS = 200.f
let MAX_MASS = 1000.f
let BOT_SPEED = 200f
let PLAYER_SPEED = 250f

[decs_template(prefix)]
struct AgarioPlayer
    canCombineWithTeam: bool
    pos: float2
    vel: float2
    radius: float
    color: uint
    screenScale : float
    player: bool = true
    bulletSpeedBonus: float
    lessMassPercentPerSec: float
    unit: bool
    team: int
    applyInput: bool
    // countAsAlive: bool
    createdAtTime: float
    //mass: int

[decs_template(prefix)]
struct AgarioBot
    pos: float2
    vel: float2
    radius: float
    color: uint
    bot: bool = true
    botLeader: bool
    pointOfInterest: float2
    eidOfInterest: EntityId
    bulletSpeedBonus: float
    unit: bool
    team: int
    applyInput: bool
    createdAtTime: float
    canCombineWithTeam: bool
    lessMassPercentPerSec: float
    // countAsAlive: bool

[decs_template(prefix)]
struct eatPoints
    pos: float2
    radius: float
    color: uint
    addRadius: float

[decs_template(prefix)]
struct hud
    hud: bool //tag
    pos: float2

[decs_template(prefix)]
struct bullet
    pos: float2
    color: uint
    speed: float
    viscosity: float
    dir: float2
    bulletRadius:float
    bulletOwnerTeam: int
    bullet: bool = true //tag

[decs_template(prefix)]
struct ammoRangeBonus
    pos: float2

[decs_template(prefix)]
struct Camera
    pos: float2
    scale: float

[decs_template(prefix)]
struct infoMessege
    infoText: string
    destroyAtTime: float
    color: uint

[decs(stage = update, REQUIRE=infoText)]
def update_info_messege_live(eid: EntityId;
                             destroyAtTime: float)
    if get_time_after_start() > destroyAtTime
        delete_entity(eid)

[decs(stage = draw)]
def draw_info_messege(infoText: string;
                      color: uint)
    let fonsSizeBefore = get_current_font_size()
    set_font_size(40)
    let textSize = get_text_size(infoText)
    var textPos = float2(0,0)
    query <| $ [REQUIRE(player)] (pos: float2)
        textPos = pos
    textPos.y += float(get_screen_height() / 4)

    text_out(textPos.x - textSize.x * 0.5f, textPos.y, infoText , color)
    set_font_size(fonsSizeBefore)

def square(x)
    return x*x

def applyVelocityToUnit(physEid: EntityId; var physPos: float2&; var vel: float2&; physTeam: int; collisionRadius: float; physCanCombineWithTeam: bool)
//collide_border
    if (physPos.x <= -LOC_SIZE && vel.x < 0f)|| (physPos.x >= LOC_SIZE && vel.x > 0f)
        vel.x=0f
    if (physPos.y <= -LOC_SIZE && vel.y < 0f)|| (physPos.y >= LOC_SIZE && vel.y > 0f)
        vel.y=0f
    physPos += vel
// collide_to_teammates
    query <| $ (eid: EntityId; pos: float2; team: int; radius: float; canCombineWithTeam: bool)
        let relativeVec = pos - physPos
        let relativeVecLength = length(relativeVec)
        if physEid != eid && (physTeam == team && (!canCombineWithTeam || !physCanCombineWithTeam)) && collisionRadius + radius > relativeVecLength
            physPos += relativeVec / relativeVecLength * (relativeVecLength - collisionRadius - radius)


[decs(stage = sec_update)]
def update_combine_units_state(createdAtTime: float;
                               radius: float;
                               var canCombineWithTeam: bool&;
                               combineTimeMul: float = 0.05f)
    if get_time_after_start() > (createdAtTime + combineTimeMul * radius)
        canCombineWithTeam = true

def init_hud()
    create_entity <| @ ( eid, cmp )
        cmp |> set("eid", eid)
        apply_decs_template(cmp, [[hud]])

def create_camera()
    create_entity <| @ ( eid, cmp )
        cmp |> set("eid", eid)
        apply_decs_template(cmp, [[Camera]])

def create_message(text: string; initColor: uint = 0x00FF00; lifeTime = 5.f)
    create_entity <| @ ( eid, cmp )
        cmp |> set("eid", eid)
        apply_decs_template(cmp, [[infoMessege infoText = text, destroyAtTime = get_time_after_start() + lifeTime, color = initColor]])

def make_player(pos, vel: float2; radius: float; team = -1; initApplyInput = true)
    var playerTeam = team
    if playerTeam < 0
        playerTeam = FREE_TEAM_ID
        FREE_TEAM_ID++
    create_entity <| @ ( eid, cmp )
        cmp |> set("eid", eid)
        apply_decs_template(cmp, [[AgarioPlayer
                                   applyInput = initApplyInput,
                                   team = playerTeam,
                                   player = true,
                                   unit = true,
                                //    countAsAlive = true,
                                   bulletSpeedBonus = 1f,
                                   lessMassPercentPerSec = 0.005,
                                   pos = pos,
                                   vel = vel,
                                   radius = radius,
                                   screenScale = 1.0,
                                   canCombineWithTeam = initApplyInput,
                                   createdAtTime = get_time_after_start(),
                                   color =  make_color(255f, 255f, 255f)]])

def make_bot_player(pos, vel: float2; radius: float; team = -1; initApplyInput = true; initBotLeader = false; inColor = uint(0))
    var botPlayerTeam = team
    if botPlayerTeam < 0
        botPlayerTeam = FREE_TEAM_ID
        FREE_TEAM_ID++
    let colorF = random_float4(RAND_SEED)
    create_entity <| @ ( eid, cmp )
        cmp |> set("eid", eid)
        apply_decs_template(cmp, [[AgarioBot
                                   applyInput = initApplyInput,
                                   team = botPlayerTeam,
                                   bulletSpeedBonus = 1f,
                                   lessMassPercentPerSec = 0.005,
                                   pos = pos,
                                   vel = vel,
                                   radius = radius,
                                   botLeader= initBotLeader,
                                   canCombineWithTeam = initApplyInput,
                                   createdAtTime = get_time_after_start(),
                                   color =  inColor > uint(0) ? inColor : make_color(colorF.x, colorF.y, colorF.z)]])

def make_bot_player_in_random_pos()
    make_bot_player(float2(random_float(RAND_SEED)*LOC_SIZE*2.f - LOC_SIZE, random_float(RAND_SEED)*LOC_SIZE*2.f - LOC_SIZE), float2(0f,0f),
                    clamp(random_float(RAND_SEED) * MAX_START_MASS, START_MASS, MAX_START_MASS), -1, true, true)

def make_eat(pos: float2)
    let colorF = random_float4(RAND_SEED)
    create_entity <| @ ( eid, cmp )
        cmp |> set("eid", eid)
        apply_decs_template(cmp, [[eatPoints pos = pos, radius = 10.f, color = make_color(colorF.x, colorF.y, colorF.z), addRadius = 1.5f]])

def make_eat_in_random_pos()
    make_eat(float2(random_float(RAND_SEED)*LOC_SIZE*2.f - LOC_SIZE, random_float(RAND_SEED)*LOC_SIZE*2.f - LOC_SIZE))

def create_bullet(ownerTeam: int; pos, dir: float2; bulletType: int; bulletSpeedBonus: float; bulletRangeBonus = 1.0)
    //worth case
    var initSpeed = 1000.0
    var initviscosity = 0.1
    var radius = 10f
    var initColor = make_color(255f, 0f, 0f)
    var resultDir = dir
    let angle = random_float(RAND_SEED) * 0.4f * bulletRangeBonus
    resultDir.x=dir.x*cos(angle)-dir.y*sin(angle)
    resultDir.y=dir.y*cos(angle)+dir.x*sin(angle)

    if bulletType == 0
        //initColor = /...
        initSpeed = 1500.0
        initviscosity = 0.1

    initSpeed *= bulletSpeedBonus
    let colorF = random_float4(RAND_SEED)
    create_entity <| @ ( eid, cmp )
        cmp |> set("eid", eid)
        apply_decs_template(cmp, [[bullet bulletOwnerTeam = ownerTeam, pos = pos, bulletRadius= radius, dir = resultDir, speed = initSpeed, color = initColor, viscosity = initviscosity]])

def split_player_unit_entity(partsCount:int = 2)
    query <| $ [REQUIRE(player)] (pos: float2;
                                  team: int;
                                  vel: float2;
                                  var radius: float;
                                  applyingInputTime: float = 0.5f)
        let maxParts = int(radius / START_MASS)
        var needParts = partsCount
        needParts = partsCount <= int(radius / START_MASS) ? partsCount : maxParts
        let resultedRadius = radius / float(needParts)
        radius = resultedRadius
        let normilizedVel = vel/length(vel)
        for i in range(needParts -1)
            make_player(pos + normilizedVel * 1.1f * resultedRadius, 5.f*vel,  resultedRadius,team, false)

def split_bot_player_unit_entity(botTeam: int; partsCount:int = 2)
    query <| $ [REQUIRE(bot)] (pos: float2;
                               team: int;
                               vel: float2;
                               var radius: float;
                               color: uint;
                               applyingInputTime: float = 0.5f)
        if team != botTeam
            return
        let maxParts = int(radius / START_MASS)
        var needParts = partsCount
        needParts = partsCount <= int(radius / START_MASS) ? partsCount : maxParts
        let resultedRadius = radius / float(needParts)
        radius = resultedRadius
        let normilizedVel = vel/length(vel)
        for i in range(needParts -1)
            make_bot_player(pos + normilizedVel * 1.1f * resultedRadius, 5.f*vel,  resultedRadius, team, false, false, color)

def local_player_shoot()
    query <| $ [REQUIRE(player)] (eid: EntityId;
                                  pos: float2;
                                  var radius: float&;
                                  vel: float2;
                                  team: int;
                                  bulletSpeedBonus: float;
                                  shootingCost: float = 0.5f;
                                  bulletType: int = 0)
        if radius > START_MASS+ shootingCost
            let initDir = vel / length(vel)
            create_bullet(team, pos + radius * initDir, initDir, bulletType, bulletSpeedBonus)
            radius -= shootingCost

[decs(stage = update)]
def update_player_input_phys(eid: EntityId;
                             var applyInput : bool&;
                             var pos: float2&;
                             team: int;
                             radius: float;
                             canCombineWithTeam: bool;
                             var screenScale: float&;
                             var vel: float2&) //saparate to 2 systems
    let dt = get_delta_time()
    if !applyInput
        applyVelocityToUnit(eid, pos, vel, team, radius, canCombineWithTeam)
        var speed = length(vel)
        let normilizedVel = vel / speed
        speed = approach(speed, 0f, dt, 0.8f)
        vel = normilizedVel * speed
        if speed < 2.f
            applyInput = true
        return
    let mousePos = get_mouse_position()
    let mouseVec = mousePos - world_to_screen(pos)
    let scale = clamp(length(mouseVec) / 1000f, 0.0, 0.5) + (radius / START_MASS)/50f // NEED REWORK, REMOVE ME, MUST BE ONLY CAMERA CODE
    screenScale = approach(screenScale, scale, dt, 1.f)//now world_to_screen p.pos equal center of screen (TODO)
    vel = mouseVec * dt

    let moveVelL = length(mouseVec)
    vel = (mouseVec /moveVelL) * dt * PLAYER_SPEED * clamp(moveVelL/PLAYER_SPEED, 0f, 1f)
    applyVelocityToUnit(eid, pos, vel, team, radius, canCombineWithTeam) // phys know about team?


[decs(stage = update, REQUIRE=unit)]
def pair_enemy_bullet_intersection(eid: EntityId;
                                   pos: float2;
                                   team: int;
                                   var radius: float&;
                                   saveEatenMassP = 0.3f;
                                   saveEatenMassFriendlyP = 0.8f) // bad solution
    let basePos = pos
    let baseEid = eid
    let baseTeam = team
    var baseRadius & = radius
    query <| $ [REQUIRE(unit)] (eid: EntityId;
                                pos: float2;
                                team: int;
                                radius: float;
                                botLeader: bool = false)
        if baseRadius > radius * 1.05 && length(pos - basePos) < baseRadius - radius * 0.5
            delete_entity(eid)
            //query(eid) <| $ (player: bool) // has(eid...) // restart on die
            //    make_player(float2(0f, 0f), float2(0f, 0f), START_MASS*10f)
            if (botLeader)
                var anyBotInTeamExist = false
                let botLeaderTeam = team
                let botLeaderEid = eid
                query <| $  (eid: EntityId;
                             team: int)
                    if eid != botLeaderEid && team == botLeaderTeam
                        anyBotInTeamExist = true
                if !anyBotInTeamExist
                    make_bot_player_in_random_pos()
            if baseRadius < MAX_MASS
                let saveMassMul = team == baseTeam ? saveEatenMassFriendlyP : saveEatenMassP
                baseRadius += radius * saveMassMul

    query <| $ [REQUIRE(bullet)] (eid: EntityId;
                                  bulletOwnerTeam: int;
                                  speed: float;
                                  pos: float2;
                                  bulletRadius:float)
        if team != bulletOwnerTeam && length(pos - basePos) < baseRadius + bulletRadius
            baseRadius -= bulletRadius * speed / 5000f
            if baseRadius < START_MASS
                // query(baseEid) <| $ (player: bool) // has(eid...) // restart on die
                //     make_player(float2(0f, 0f), float2(0f, 0f), START_MASS*10f)
                delete_entity(baseEid)
            delete_entity(eid)

[decs(stage = update)]
def bullet_phys(eid: EntityId;
                var pos: float2&;
                var speed: float&;
                viscosity: float;
                dir: float2)
    let dt = get_delta_time()
    speed = approach(speed, 0f, dt, 0.8f)
    if speed < 50f
        delete_entity(eid)
    pos += dir * speed * dt

def find_food(from_point: float2; objRadius: float)
    var min_dist_sq = square(LOC_SIZE)
    var point: float2 = float2(0f,0f)
    query <| $ [REQUIRE(addRadius)] (pos:float2)
        let distance = length_sq(pos-from_point)
        if distance < min_dist_sq && distance > objRadius
            min_dist_sq = distance
            point = pos
    return point

def find_interest_safety_point(from_point: float2; objRadius: float)
    var point: float2 = float2(0f,0f)//find_weapon bonus(from_point)
    if (length_sq(point) != 0f)
        return point
    return find_food(from_point, objRadius)

def find_leader_point(botTeam: int; var pointOfInterest: float2&)
    var leaderFound = false
    query <| $ (team: int; pos:float2; botLeader: bool)
        if botTeam == team && botLeader
            pointOfInterest = pos
            leaderFound = true
    return leaderFound

// split_bot_player_unit_entity
def find_enemy_targer_to_split(ownerPos: float2;
                               ownerRadius: float;
                               ownerTeam: int)
    var point: float2 = float2(0f,0f)
    query <| $ (team: int; pos:float2;  radius: float)
        let dist = length(ownerPos - pos)
        if ownerTeam != team && dist < (ownerRadius + radius) * 2f && ownerRadius > 2.2 * radius &&  ownerRadius < 3f * radius
            point = pos
    return point

def verifyAndSetLeaderForTeam(bot_team: int)
    var maxRadius = 0.f
    var leaderEid = INVALID_ENTITY_ID
    query <| $ (eid: EntityId; team: int; var botLeader: bool&;  radius: float)
        if bot_team == team
            botLeader = false
            if radius > maxRadius && bot_team == team
                leaderEid = eid
                maxRadius = radius
    query(leaderEid) <| $ (var botLeader: bool&)
        botLeader = true

[decs(stage = update, REQUIRE=pointOfInterest, before=update_bot_player_input_phys)]
def update_bot_leader(eid: EntityId;
                      team: int) //separate to 2 systems
    verifyAndSetLeaderForTeam(team)

[decs(stage = update, after=update_mass)]
def update_bot_player_input_phys(eid: EntityId;
                                 var pointOfInterest: float2&;
                                 var pos: float2&;
                                 radius: float;
                                 var applyInput: bool&;
                                 var vel: float2&;
                                 var botLeader: bool&;
                                 team: int;
                                 canCombineWithTeam: bool;
                                 minMassToSplit = 100.f) //separate to 2 systems
    let dt = get_delta_time()
    if !applyInput //move to separate system
        applyVelocityToUnit(eid, pos, vel, team, radius, canCombineWithTeam)
        var speed = length(vel)
        let normilizedVel = vel / speed
        speed = approach(speed, 0f, dt, 0.8f)
        vel = normilizedVel * speed
        if speed < 2.f
            applyInput = true
        return
    // check_danger_point
    if !botLeader
        find_leader_point(team, pointOfInterest)

    if (botLeader && (length_sq(pointOfInterest) == 0f || length_sq(pointOfInterest - pos) < square(radius)))
        pointOfInterest = find_interest_safety_point(pos, radius)

    var needSplit = false
    let enemyToSplit = minMassToSplit < radius && botLeader? find_enemy_targer_to_split(pos, radius, team): float2(0f,0f)
    if length_sq(enemyToSplit) > 0f
        pointOfInterest = enemyToSplit
        needSplit = true

    let moveVec = pointOfInterest - pos
    vel = moveVec / length(moveVec) * dt * BOT_SPEED

    applyVelocityToUnit(eid, pos, vel, team, radius, canCombineWithTeam)
    if needSplit
        split_bot_player_unit_entity(team)

[decs(stage = update, after = update_player_input)]
def update_mass(pos: float2;
                var radius: float&;
                lessMassPercentPerSec: float)
    var unitRaduis & = radius
    let unitPos = pos
    query <| $ (eid:EntityId; pos:float2; addRadius: float; radius: float )
        if (length_sq(pos - unitPos) < square(unitRaduis + radius))
            if unitRaduis < MAX_MASS
                unitRaduis += addRadius
            delete_entity(eid)
            make_eat_in_random_pos()
    let dt = get_delta_time()
    let lessMassPerSec = radius * lessMassPercentPerSec * dt
    if radius > START_MASS + lessMassPerSec
        radius -= lessMassPerSec

[decs(stage = update, after = update_player_input)]
def update_camera(var p: Camera)
    let scaleBefore = p.scale
    let dt = get_delta_time()
    var resultPos = float2(0f,0f)
    var playerCount = 0f
    var resultScreenScale = 0f
    query <| $ [REQUIRE(player)] (pos: float2;
                                  radius: float;
                                  screenScale: float)
        // if !applyInput
        //     return
        let camWeight = radius/100f
        resultPos += camWeight*pos
        playerCount += camWeight
        resultScreenScale += camWeight*screenScale
    p.pos = approach(p.pos,
                     length_sq(resultPos) > 0.f ?  resultPos / float(playerCount) : p.pos,
                     dt,
                     0.8f)
    p.scale = approach(p.scale,
                       resultScreenScale > 0f ? resultScreenScale / float(playerCount) : p.scale,
                       dt,
                       0.8f)
    setup_2d_camera(p.pos, clamp(1.0 - p.scale, 0.15, 0.8))

[decs(stage = draw)]
def draw_units(pos: float2;
               radius: float;
               color: uint;
               text: string = "")
    let screenPos = world_to_screen(pos)
    if int(screenPos.x + radius) > 0 && int(screenPos.x - radius) < get_screen_width() && int(screenPos.y + radius) > 0 && int(screenPos.y - radius) < get_screen_height()
        fill_circle(pos.x, pos.y, radius, color)
        let resText = text + "mass: {radius}"
        let fonsSizeBefore = get_current_font_size()
        set_font_size(int(radius) / 6)
        let textSize = get_text_size(resText)
        text_out(pos.x - textSize.x * 0.5f, pos.y - textSize.y * 0.5f, text + "mass: {radius}" , 0x000000)
        set_font_size(fonsSizeBefore)

[decs(stage = draw, REQUIRE=bullet)]
def draw_bullets(pos: float2;
                 dir: float2;
                 bulletRadius: float = 40f;
                 color: uint)
    let screenPos = world_to_screen(pos)
    for i in range(4)
        let drawPos = pos + dir * bulletRadius * float(i)
        fill_circle(drawPos.x, drawPos.y, bulletRadius, color)

var DIRTY_HACK_GAME_STATE=2

[export]
def initialize(is_hard_reload: bool)
    set_antialiasing(8)
    set_window_title("DAgario")
   // disable_auto_upscale()
    if is_hard_reload
        create_camera()
        init_hud()
        //make_player(float2(0f, 0f), float2(0f, 0f), START_MASS*50f)
        //make_player(float2(0f, 400f), float2(0f, 0f), START_MASS*10f)
       // let utc = get_clock() - [[clock]]
        RAND_SEED = random_seed(int(500))
        for i in range(INIT_FOOD_COUNT)
            make_eat_in_random_pos()
        for i in range(BOTS_POP)
            make_bot_player_in_random_pos()
        commit()

var DIRTY_HACK_SEPARATE_CLICK_SPLIT = false // REMOVE ME PLS
// 0 game
// 1 restart
// 2 menu

[export]
def act(dt: float)
    if get_key(VK_ESCAPE)
        schedule_quit_game()
    if get_mouse_button(MB_RIGHT) || get_key(VK_SPACE)
        local_player_shoot()
    if get_mouse_button(MB_LEFT) || get_key(VK_RCONTROL)
        if !DIRTY_HACK_SEPARATE_CLICK_SPLIT
            split_player_unit_entity()
            DIRTY_HACK_SEPARATE_CLICK_SPLIT = true
    else
        DIRTY_HACK_SEPARATE_CLICK_SPLIT = false
// bug? i can't create player in pair_enemy_bullet_intersection
    var playerExist = false
    query <| $ (player: bool) // has(eid...) // restart on die
        playerExist = true
    if !playerExist && DIRTY_HACK_GAME_STATE == 0
       // create_message("You loose, R to restart", 0xFF0000, 5.f)
        if DIRTY_HACK_GAME_STATE == 0
            DIRTY_HACK_GAME_STATE = 1
    if DIRTY_HACK_GAME_STATE != 0
        query <| $ (var scale: float&;
                    var pos: float2&) // has(eid...) // restart on die
            scale = 0.8f
            pos = float2(0f,0f)
    if get_key(VK_R)
        query <| $ [REQUIRE(player)] (eid: EntityId)
            delete_entity(eid)
        make_player(float2(0f, 0f), float2(0f, 0f), START_MASS*10f)
        create_message("Game started")
        DIRTY_HACK_GAME_STATE = 0

    decs_stage("update")
    decs_stage("sec_update")


[decs(stage = drawHud)]
def save_and_draw_hud_info(hud: bool) //separate
    var aliveCount = 0
    var summOfMass = 0f
    var maxMass = 0f

    var cameraScale = 1.f
    query <| $ (scale: float)
        cameraScale = scale
    query <| $ [REQUIRE(unit)] (radius: float)
        if radius > maxMass
            maxMass = radius
        summOfMass += radius
        aliveCount++

    let hudCorner = screen_to_world(float2(20f,20f))

    let fonsSizeBefore = get_current_font_size()
    let fSize = int(15f / clamp(1.0 - cameraScale, 0.15, 0.8))
    set_font_size(fSize) //must scaled by camera
    text_out(hudCorner.x, hudCorner.y, "DAgario", 0x819720) // under units
    text_out(hudCorner.x, hudCorner.y + float(fSize), "alive {aliveCount}", 0x819720) // under units
    text_out(hudCorner.x, hudCorner.y + 2f * float(fSize), "max mass {maxMass}", 0x819720) // under units
    text_out(hudCorner.x, hudCorner.y + 3f * float(fSize), "summ of mass {summOfMass}", 0x819720) // under units
    set_font_size(fonsSizeBefore)

[export]
def draw
    let fonsSizeBefore = get_current_font_size()
    set_font_size(150)
    text_out(0, 0, "Welcome to DAgario DEMO GAME", 0x073507) // under units
    set_font_size(fonsSizeBefore)
    decs_stage("draw")

    set_font_size(250)
    if DIRTY_HACK_GAME_STATE == 1
        text_out(0, 300, "PRESS R TO RESTART", 0xFF0000)
    elif DIRTY_HACK_GAME_STATE == 2
        text_out(0, 300, "PRESS R TO START", 0xFF0000)
        set_font_size(150)
        text_out(0, 600, "MBL to split", 0xFF0000)
        text_out(0, 750, "MBR to shoot", 0xFF0000)
        text_out(0, 900, "It's demo, bonuses will be later", 0xFFFF00)
    set_font_size(fonsSizeBefore)

    decs_stage("drawHud")
