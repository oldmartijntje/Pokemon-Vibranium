#===============================================================================
# Fixed Howl always failing.
#===============================================================================
class Battle::Move::RaiseTargetAttack1 < Battle::Move
  def pbMoveFailed?(user, targets)
    return false if damagingMove?
    failed = true
    targets.each do |b|
      next if !b.pbCanRaiseStatStage?(:ATTACK, user, self)
      failed = false
      break
    end
    if failed
      @battle.pbDisplay(_INTL("But it failed!"))
      return true
    end
    return false
  end
end

#===============================================================================
# Fixed Dauntless Shield raising the wrong stat.
#===============================================================================
Battle::AbilityEffects::OnSwitchIn.add(:DAUNTLESSSHIELD,
  proc { |ability, battler, battle, switch_in|
    battler.pbRaiseStatStageByAbility(:DEFENSE, 1, battler)
  }
)

#===============================================================================
# Fixed error when calculating type effectiveness against a Pokémon with no
# types.
#===============================================================================
module Effectiveness
  def calculate(attack_type, defend_type1, defend_type2 = nil, defend_type3 = nil)
    mod1 = (defend_type1) ? calculate_one(attack_type, defend_type1) : NORMAL_EFFECTIVE_ONE
    mod2 = NORMAL_EFFECTIVE_ONE
    mod3 = NORMAL_EFFECTIVE_ONE
    if defend_type2 && defend_type1 != defend_type2
      mod2 = calculate_one(attack_type, defend_type2)
    end
    if defend_type3 && defend_type1 != defend_type3 && defend_type2 != defend_type3
      mod3 = calculate_one(attack_type, defend_type3)
    end
    return mod1 * mod2 * mod3
  end
end

#===============================================================================
# Fixed Xerneas/Zacian/Zamazenta not being their alternate form throughout
# battle.
#===============================================================================
class Battle::Peer
  def pbOnStartingBattle(battle, pkmn, wild = false)
    f = MultipleForms.call("getFormOnStartingBattle", pkmn, wild)
    pkmn.form = f if f
    MultipleForms.call("changePokemonOnStartingBattle", pkmn, battle)
  end
end

class Battle
  alias __hotfixes__pbEnsureParticipants pbEnsureParticipants
  def pbEnsureParticipants
    __hotfixes__pbEnsureParticipants
    pbParty(0).each { |pkmn| @peer.pbOnStartingBattle(self, pkmn, wildBattle?) if pkmn }
    pbParty(1).each { |pkmn| @peer.pbOnStartingBattle(self, pkmn, wildBattle?) if pkmn }
  end
end

MultipleForms.register(:XERNEAS, {
  "getFormOnStartingBattle" => proc { |pkmn, wild|
    next 1
  },
  "getFormOnLeavingBattle" => proc { |pkmn, battle, usedInBattle, endBattle|
    next 0 if endBattle
  }
})

MultipleForms.register(:ZACIAN, {
  "getFormOnStartingBattle" => proc { |pkmn, wild|
    next 1 if pkmn.hasItem?(:RUSTEDSWORD)
    next 0
  },
  "changePokemonOnStartingBattle" => proc { |pkmn, battle|
    if GameData::Move.exists?(:BEHEMOTHBLADE) && pkmn.hasItem?(:RUSTEDSWORD)
      pkmn.moves.each { |move| move.id = :BEHEMOTHBLADE if move.id == :IRONHEAD }
    end
  },
  "getFormOnLeavingBattle" => proc { |pkmn, battle, usedInBattle, endBattle|
    next 0 if endBattle
  },
  "changePokemonOnLeavingBattle" => proc { |pkmn, battle, usedInBattle, endBattle|
    if endBattle
      pkmn.moves.each { |move| move.id = :IRONHEAD if move.id == :BEHEMOTHBLADE }
    end
  }
})

MultipleForms.register(:ZAMAZENTA, {
  "getFormOnStartingBattle" => proc { |pkmn, wild|
    next 1 if pkmn.hasItem?(:RUSTEDSHIELD)
    next 0
  },
  "changePokemonOnStartingBattle" => proc { |pkmn, battle|
    if GameData::Move.exists?(:BEHEMOTHBASH) && pkmn.hasItem?(:RUSTEDSHIELD)
      pkmn.moves.each { |move| move.id = :BEHEMOTHBASH if move.id == :IRONHEAD }
    end
  },
  "getFormOnLeavingBattle" => proc { |pkmn, battle, usedInBattle, endBattle|
    next 0 if endBattle
  },
  "changePokemonOnLeavingBattle" => proc { |pkmn, battle, usedInBattle, endBattle|
    if endBattle
      pkmn.moves.each { |move| move.id = :IRONHEAD if move.id == :BEHEMOTHBASH }
    end
  }
})

#===============================================================================
# Fixed incorrect damage multiplier for Grav Apple in gravity.
#===============================================================================
class Battle::Move::LowerTargetDefense1PowersUpInGravity < Battle::Move::LowerTargetDefense1
  def pbBaseDamage(baseDmg, user, target)
    baseDmg = baseDmg * 3 / 2 if @battle.field.effects[PBEffects::Gravity] > 0
    return baseDmg
  end
end

class Battle::AI
  alias __hotfixes__pbGetMoveScoreFunctionCode pbGetMoveScoreFunctionCode
  def pbGetMoveScoreFunctionCode(score, move, user, target, skill = 100)
    case move.function
    when "LowerTargetDefense1PowersUpInGravity"
      if target.pbCanLowerStatStage?(:DEFENSE, user)
        score += 20
        score += target.stages[:DEFENSE] * 20
      else
        score -= 90
      end
      score += 30 if @battle.field.effects[PBEffects::Gravity] > 0
    else
      return __hotfixes__pbGetMoveScoreFunctionCode(score, move, user, target, skill)
    end
    return score
  end
end

#===============================================================================
# Fixed error when applying Sea of Fire's damage.
#===============================================================================
class Battle
  def pbEORSeaOfFireDamage(priority = nil)
    priority = pbPriority(true) if !priority
    2.times do |side|
      next if sides[side].effects[PBEffects::SeaOfFire] == 0
      pbCommonAnimation("SeaOfFire") if side == 0
      pbCommonAnimation("SeaOfFireOpp") if side == 1
      priority.each do |battler|
        next if battler.opposes?(side)
        next if !battler.takesIndirectDamage? || battler.pbHasType?(:FIRE)
        @scene.pbDamageAnimation(battler)
        battler.pbTakeEffectDamage(battler.totalhp / 8, false) { |hp_lost|
          pbDisplay(_INTL("{1} is hurt by the sea of fire!", battler.pbThis))
        }
      end
    end
  end
end

#===============================================================================
# Fixed Gorilla Tactics also boosting Special Attack.
#===============================================================================
Battle::AbilityEffects::DamageCalcFromUser.add(:GORILLATACTICS,
  proc { |ability, user, target, move, mults, baseDmg, type|
    mults[:attack_multiplier] *= 1.5 if move.physicalMove?
  }
)

#===============================================================================
# Fixed incorrect capitalisation in message when Aurora Veil wears off.
#===============================================================================
class Battle
  alias __hotfixes__pbEORCountDownSideEffect pbEORCountDownSideEffect

  def pbEORCountDownSideEffect(side, effect, msg)
    if effect == PBEffects::AuroraVeil
      msg = _INTL("{1}'s Aurora Veil wore off!", @battlers[side].pbTeam)
    end
    __hotfixes__pbEORCountDownSideEffect(side, effect, msg)
  end
end
