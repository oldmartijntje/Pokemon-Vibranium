#===============================================================================
# Fixed incorrect message when choosing a Pokémon to withdraw from Day Care.
#===============================================================================
class DayCare
  def self.choose(message, choice_var)
    day_care = $PokemonGlobal.day_care
    case day_care.count
    when 0
      raise _INTL("No Pokémon found in Day Care to choose from.")
    when 1
      day_care.slots.each_with_index { |slot, i| $game_variables[choice_var] = i if slot.filled? }
    else
      commands = []
      indices = []
      day_care.slots.each_with_index do |slot, i|
        choice_text = slot.choice_text
        next if !choice_text
        commands.push(choice_text)
        indices.push(i)
      end
      commands.push(_INTL("CANCEL"))
      command = pbMessage(message, commands, commands.length)
      $game_variables[choice_var] = (command == commands.length - 1) ? -1 : indices[command]
    end
  end
end

#===============================================================================
# Fixed incorrect status condition icon used for fainted Pokémon and Pokémon
# with Pokérus.
#===============================================================================
class PokemonPartyPanel < SpriteWrapper
  def refresh
    return if disposed?
    return if @refreshing
    @refreshing = true
    if @panelbgsprite && !@panelbgsprite.disposed?
      if self.selected
        if self.preselected
          @panelbgsprite.changeBitmap("swapsel2")
        elsif @switching
          @panelbgsprite.changeBitmap("swapsel")
        elsif @pokemon.fainted?
          @panelbgsprite.changeBitmap("faintedsel")
        else
          @panelbgsprite.changeBitmap("ablesel")
        end
      else
        if self.preselected
          @panelbgsprite.changeBitmap("swap")
        elsif @pokemon.fainted?
          @panelbgsprite.changeBitmap("fainted")
        else
          @panelbgsprite.changeBitmap("able")
        end
      end
      @panelbgsprite.x     = self.x
      @panelbgsprite.y     = self.y
      @panelbgsprite.color = self.color
    end
    if @hpbgsprite && !@hpbgsprite.disposed?
      @hpbgsprite.visible = (!@pokemon.egg? && !(@text && @text.length > 0))
      if @hpbgsprite.visible
        if self.preselected || (self.selected && @switching)
          @hpbgsprite.changeBitmap("swap")
        elsif @pokemon.fainted?
          @hpbgsprite.changeBitmap("fainted")
        else
          @hpbgsprite.changeBitmap("able")
        end
        @hpbgsprite.x     = self.x + 96
        @hpbgsprite.y     = self.y + 50
        @hpbgsprite.color = self.color
      end
    end
    if @ballsprite && !@ballsprite.disposed?
      @ballsprite.changeBitmap((self.selected) ? "sel" : "desel")
      @ballsprite.x     = self.x + 10
      @ballsprite.y     = self.y
      @ballsprite.color = self.color
    end
    if @pkmnsprite && !@pkmnsprite.disposed?
      @pkmnsprite.x        = self.x + 60
      @pkmnsprite.y        = self.y + 40
      @pkmnsprite.color    = self.color
      @pkmnsprite.selected = self.selected
    end
    if @helditemsprite&.visible && !@helditemsprite.disposed?
      @helditemsprite.x     = self.x + 62
      @helditemsprite.y     = self.y + 48
      @helditemsprite.color = self.color
    end
    if @overlaysprite && !@overlaysprite.disposed?
      @overlaysprite.x     = self.x
      @overlaysprite.y     = self.y
      @overlaysprite.color = self.color
    end
    if @refreshBitmap
      @refreshBitmap = false
      @overlaysprite.bitmap&.clear
      basecolor   = Color.new(248, 248, 248)
      shadowcolor = Color.new(40, 40, 40)
      pbSetSystemFont(@overlaysprite.bitmap)
      textpos = []
      # Draw Pokémon name
      textpos.push([@pokemon.name, 96, 22, 0, basecolor, shadowcolor])
      if !@pokemon.egg?
        if !@text || @text.length == 0
          # Draw HP numbers
          textpos.push([sprintf("% 3d /% 3d", @pokemon.hp, @pokemon.totalhp), 224, 66, 1, basecolor, shadowcolor])
          # Draw HP bar
          if @pokemon.hp > 0
            w = @pokemon.hp * 96 / @pokemon.totalhp.to_f
            w = 1 if w < 1
            w = ((w / 2).round) * 2
            hpzone = 0
            hpzone = 1 if @pokemon.hp <= (@pokemon.totalhp / 2).floor
            hpzone = 2 if @pokemon.hp <= (@pokemon.totalhp / 4).floor
            hprect = Rect.new(0, hpzone * 8, w, 8)
            @overlaysprite.bitmap.blt(128, 52, @hpbar.bitmap, hprect)
          end
          # Draw status
          status = -1
          if @pokemon.fainted?
            status = GameData::Status.count - 1
          elsif @pokemon.status != :NONE
            status = GameData::Status.get(@pokemon.status).icon_position
          elsif @pokemon.pokerusStage == 1
            status = GameData::Status.count
          end
          if status >= 0
            statusrect = Rect.new(0, 16 * status, 44, 16)
            @overlaysprite.bitmap.blt(78, 68, @statuses.bitmap, statusrect)
          end
        end
        # Draw gender symbol
        if @pokemon.male?
          textpos.push([_INTL("♂"), 224, 22, 0, Color.new(0, 112, 248), Color.new(120, 184, 232)])
        elsif @pokemon.female?
          textpos.push([_INTL("♀"), 224, 22, 0, Color.new(232, 32, 16), Color.new(248, 168, 184)])
        end
        # Draw shiny icon
        if @pokemon.shiny?
          pbDrawImagePositions(@overlaysprite.bitmap,
                               [["Graphics/Pictures/shiny", 80, 48, 0, 0, 16, 16]])
        end
      end
      pbDrawTextPositions(@overlaysprite.bitmap, textpos)
      # Draw level text
      if !@pokemon.egg?
        pbDrawImagePositions(@overlaysprite.bitmap,
                             [["Graphics/Pictures/Party/overlay_lv", 20, 70, 0, 0, 22, 14]])
        pbSetSmallFont(@overlaysprite.bitmap)
        pbDrawTextPositions(@overlaysprite.bitmap,
                            [[@pokemon.level.to_s, 42, 68, 0, basecolor, shadowcolor]])
      end
      # Draw annotation text
      if @text && @text.length > 0
        pbSetSystemFont(@overlaysprite.bitmap)
        pbDrawTextPositions(@overlaysprite.bitmap,
                            [[@text, 96, 62, 0, basecolor, shadowcolor]])
      end
    end
    @refreshing = false
  end
end

class PokemonSummary_Scene
  def drawPage(page)
    if @pokemon.egg?
      drawPageOneEgg
      return
    end
    @sprites["itemicon"].item = @pokemon.item_id
    overlay = @sprites["overlay"].bitmap
    overlay.clear
    base   = Color.new(248, 248, 248)
    shadow = Color.new(104, 104, 104)
    # Set background image
    @sprites["background"].setBitmap("Graphics/Pictures/Summary/bg_#{page}")
    imagepos = []
    # Show the Poké Ball containing the Pokémon
    ballimage = sprintf("Graphics/Pictures/Summary/icon_ball_%s", @pokemon.poke_ball)
    imagepos.push([ballimage, 14, 60])
    # Show status/fainted/Pokérus infected icon
    status = -1
    if @pokemon.fainted?
      status = GameData::Status.count - 1
    elsif @pokemon.status != :NONE
      status = GameData::Status.get(@pokemon.status).icon_position
    elsif @pokemon.pokerusStage == 1
      status = GameData::Status.count
    end
    if status >= 0
      imagepos.push(["Graphics/Pictures/statuses", 124, 100, 0, 16 * status, 44, 16])
    end
    # Show Pokérus cured icon
    if @pokemon.pokerusStage == 2
      imagepos.push([sprintf("Graphics/Pictures/Summary/icon_pokerus"), 176, 100])
    end
    # Show shininess star
    if @pokemon.shiny?
      imagepos.push([sprintf("Graphics/Pictures/shiny"), 2, 134])
    end
    # Draw all images
    pbDrawImagePositions(overlay, imagepos)
    # Write various bits of text
    pagename = [_INTL("INFO"),
                _INTL("TRAINER MEMO"),
                _INTL("SKILLS"),
                _INTL("MOVES"),
                _INTL("RIBBONS")][page - 1]
    textpos = [
      [pagename, 26, 22, 0, base, shadow],
      [@pokemon.name, 46, 68, 0, base, shadow],
      [@pokemon.level.to_s, 46, 98, 0, Color.new(64, 64, 64), Color.new(176, 176, 176)],
      [_INTL("Item"), 66, 324, 0, base, shadow]
    ]
    # Write the held item's name
    if @pokemon.hasItem?
      textpos.push([@pokemon.item.name, 16, 358, 0, Color.new(64, 64, 64), Color.new(176, 176, 176)])
    else
      textpos.push([_INTL("None"), 16, 358, 0, Color.new(192, 200, 208), Color.new(208, 216, 224)])
    end
    # Write the gender symbol
    if @pokemon.male?
      textpos.push([_INTL("♂"), 178, 68, 0, Color.new(24, 112, 216), Color.new(136, 168, 208)])
    elsif @pokemon.female?
      textpos.push([_INTL("♀"), 178, 68, 0, Color.new(248, 56, 32), Color.new(224, 152, 144)])
    end
    # Draw all text
    pbDrawTextPositions(overlay, textpos)
    # Draw the Pokémon's markings
    drawMarkings(overlay, 84, 292)
    # Draw page-specific information
    case page
    when 1 then drawPageOne
    when 2 then drawPageTwo
    when 3 then drawPageThree
    when 4 then drawPageFour
    when 5 then drawPageFive
    end
  end
end

#===============================================================================
# Fixed incorrect Pokémon icons shown in Ready Menu if there are eggs in the
# party.
#===============================================================================
def pbUseKeyItem
  moves = [:CUT, :DEFOG, :DIG, :DIVE, :FLASH, :FLY, :HEADBUTT, :ROCKCLIMB,
           :ROCKSMASH, :SECRETPOWER, :STRENGTH, :SURF, :SWEETSCENT, :TELEPORT,
           :WATERFALL, :WHIRLPOOL]
  real_moves = []
  moves.each do |move|
    $player.party.each_with_index do |pkmn, i|
      next if pkmn.egg? || !pkmn.hasMove?(move)
      real_moves.push([move, i]) if pbCanUseHiddenMove?(pkmn, move, false)
    end
  end
  real_items = []
  $bag.registered_items.each do |i|
    itm = GameData::Item.get(i).id
    real_items.push(itm) if $bag.has?(itm)
  end
  if real_items.length == 0 && real_moves.length == 0
    pbMessage(_INTL("An item in the Bag can be registered to this key for instant use."))
  else
    $game_temp.in_menu = true
    $game_map.update
    sscene = PokemonReadyMenu_Scene.new
    sscreen = PokemonReadyMenu.new(sscene)
    sscreen.pbStartReadyMenu(real_moves, real_items)
    $game_temp.in_menu = false
  end
end
