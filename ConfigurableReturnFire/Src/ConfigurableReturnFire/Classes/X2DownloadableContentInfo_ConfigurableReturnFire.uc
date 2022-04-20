//---------------------------------------------------------------------------------------
//  FILE:   XComDownloadableContentInfo_[WOTC]ConfigurableReturnFire.uc
//
//	Use the X2DownloadableContentInfo class to specify unique mod behavior when the
//  player creates a new campaign or loads a saved game.
//
//---------------------------------------------------------------------------------------
//  Copyright (c) 2016 Firaxis Games, Inc. All rights reserved.
//---------------------------------------------------------------------------------------

class X2DownloadableContentInfo_ConfigurableReturnFire extends X2DownloadableContentInfo
	config(ConfigurableReturnFire);

var config Int			SecondaryReturnFireShots,
						PrimaryReturnFireShots,
						DarkEventReturnFireShots,
						ChosenReturnFireShots,
						SecondaryReturnFireChance,
						PrimaryReturnFireChance,
						DarkEventReturnFireChance;

var config Bool			SecondaryReturnFireOnlyWhenMiss,
						PrimaryReturnFireOnlyWhenMiss,
						DarkEventReturnFireOnlyWhenMiss,
						ChosenReturnFireOnlyWhenMiss,
						SecondaryReturnFirePreEmptive,
						PrimaryReturnFirePreEmptive,
						DarkEventReturnFirePreEmptive,
						ChosenReturnFirePreEmptive;

var config Array<Name>	ReturnFireWeapons,
						ReactionFireAbilitiesToFix;


static event OnPostTemplatesCreated()
{
	ModifyReturnFireAbilities();
	ReactionFireFix();
	AddReturnFireToMoreWeapons();
}


static function ModifyReturnFireAbilities()
{
	local X2AbilityTemplateManager			AllAbilities;
	local X2AbilityTemplate					Template;
	local X2Effect							Effect;
	local X2Effect_CoveringFire				CoveringEffect;

	AllAbilities = class'X2AbilityTemplateManager'.static.GetAbilityTemplateManager();

	// This is the default Sharpshooter Return Fire ability
	// Localization references secondary weapon
	Template = AllAbilities.FindAbilityTemplate('ReturnFire');
	foreach Template.AbilityTargetEffects(Effect)
	{
		CoveringEffect = X2Effect_CoveringFire(Effect);
		if (Effect != none)
		{
			CoveringEffect.MaxPointsPerTurn = default.SecondaryReturnFireShots;
			CoveringEffect.ActivationPercentChance = default.SecondaryReturnFireChance;
			CoveringEffect.bOnlyWhenAttackMisses = (default.SecondaryReturnFireOnlyWhenMiss && !default.SecondaryReturnFirePreEmptive);
			CoveringEffect.bPreEmptiveFire = default.SecondaryReturnFirePreEmptive;
			break;
		}
	}
	// This is Return Fire for Skirmishers (and potentially others without pistols if added with mods)
	// It is essentially just a copy of the Sharpshooter one but the localization can refer to the primary weapon this way
	Template = AllAbilities.FindAbilityTemplate('SkirmisherReturnFire');
	foreach Template.AbilityTargetEffects(Effect)
	{
		CoveringEffect = X2Effect_CoveringFire(Effect);
		if (Effect != none)
		{
			CoveringEffect.MaxPointsPerTurn = default.PrimaryReturnFireShots;
			CoveringEffect.ActivationPercentChance = default.PrimaryReturnFireChance;
			CoveringEffect.bOnlyWhenAttackMisses = (default.PrimaryReturnFireOnlyWhenMiss && !default.PrimaryReturnFirePreEmptive);
			CoveringEffect.bPreEmptiveFire = default.PrimaryReturnFirePreEmptive;
			break;
		}
	}
	// This is Return Fire for ADVENT when the Dark Event is active
	// Gets way more dangerous with infinite uses
	Template = AllAbilities.FindAbilityTemplate('DarkEventAbility_ReturnFire');
	foreach Template.AbilityTargetEffects(Effect)
	{
		CoveringEffect = X2Effect_CoveringFire(Effect);
		if (Effect != none)
		{
			CoveringEffect.MaxPointsPerTurn = default.DarkEventReturnFireShots;
			CoveringEffect.ActivationPercentChance = default.DarkEventReturnFireChance;
			CoveringEffect.bOnlyWhenAttackMisses = (default.DarkEventReturnFireOnlyWhenMiss && !default.DarkEventReturnFirePreEmptive);
			CoveringEffect.bPreEmptiveFire = default.DarkEventReturnFirePreEmptive;
			break;
		}
	}
	// This is Return Fire for the Chosen
	// It is infinite by default but can now be configured
	Template = AllAbilities.FindAbilityTemplate('ChosenRevenge');
	foreach Template.AbilityTargetEffects(Effect)
	{
		CoveringEffect = X2Effect_CoveringFire(Effect);
		if (Effect != none)
		{
			CoveringEffect.MaxPointsPerTurn = default.ChosenReturnFireShots;
			// Chance is already configurable through SoldierSkills
			CoveringEffect.bOnlyWhenAttackMisses = (default.ChosenReturnFireOnlyWhenMiss && !default.ChosenReturnFirePreEmptive);
			CoveringEffect.bPreEmptiveFire = default.ChosenReturnFirePreEmptive;
			break;
		}
	}
}


static function ReactionFireFix()
{
	local X2AbilityTemplateManager			AbilityManager;
	local X2AbilityTemplate					AbilityTemplate;
	local X2DataTemplate					DataTemplate;
	local X2AbilityToHitCalc_StandardAim	StandardAim;
	local X2Condition_UnitEffects			SuppressedCondition;
	local X2Condition_UnitProperty			UnitCondition;
	local Array<X2DataTemplate>				DataTemplates;
	local Name								AbilityName;

	AbilityManager = class'X2AbilityTemplateManager'.static.GetAbilityTemplateManager();

	foreach default.ReactionFireAbilitiesToFix(AbilityName)
	{
		AbilityManager.FindDataTemplateAllDifficulties(AbilityName, DataTemplates);
		foreach DataTemplates(DataTemplate)
		{
			AbilityTemplate = X2AbilityTemplate(DataTemplate);

			// Disallow crits on reaction fire
			StandardAim = X2AbilityToHitCalc_StandardAim(AbilityTemplate.AbilityToHitCalc);
			if (StandardAim != none)
			{
				StandardAim.bReactionFire = true;
				StandardAim.bAllowCrit = false;
			}
			StandardAim = X2AbilityToHitCalc_StandardAim(AbilityTemplate.AbilityToHitOwnerOnMissCalc);
			if (StandardAim != none)
			{
				StandardAim.bReactionFire = true;
				StandardAim.bAllowCrit = false;
			}

			// Suppression removes activated Overwatch when used but doesn't prevent passive reaction fire without doing this
			SuppressedCondition = new class'X2Condition_UnitEffects';
			SuppressedCondition.AddExcludeEffect(class'X2Effect_Suppression'.default.EffectName, 'AA_UnitIsSuppressed');
			AbilityTemplate.AbilityShooterConditions.AddItem(SuppressedCondition);

			// TODO: prevent reactions while suppressing, the above suppression check doesn't handle that

			// Panic should prevent reactions
			UnitCondition = new class'X2Condition_UnitProperty';
			UnitCondition.ExcludePanicked = true;
			AbilityTemplate.AbilityShooterConditions.AddItem(UnitCondition);
		}
	}
}


static function AddReturnFireToMoreWeapons()
{
	local Name	WeaponName;

	foreach default.ReturnFireWeapons(WeaponName)
	{
		EnableReturnFire(WeaponName);
	}
}


static function EnableReturnFire(Name WeaponName)
{
	local X2ItemTemplateManager		AllItems;
	local X2WeaponTemplate			Template;
	local Array<X2DataTemplate>		DifficultyTemplates;
	local X2DataTemplate			DataTemplate;

	AllItems = class'X2ItemTemplateManager'.static.GetItemTemplateManager();
	Template = X2WeaponTemplate(AllItems.FindItemTemplate(WeaponName));
	if (Template != none)
	{
		AllItems.FindDataTemplateAllDifficulties(WeaponName, DifficultyTemplates);
		foreach DifficultyTemplates(DataTemplate)
		{
			Template = X2WeaponTemplate(DataTemplate);
			if (Template != none)
			{
				if (Template.Abilities.Find('PistolReturnFire') == -1) // Prevent duplicating if another mod already added it
				{
					Template.Abilities.AddItem('PistolReturnFire');
				}
			}
		}
	}
}
