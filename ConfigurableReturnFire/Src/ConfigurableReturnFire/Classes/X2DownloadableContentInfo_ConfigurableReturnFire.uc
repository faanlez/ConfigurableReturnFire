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
	local Array<X2AbilityTemplate>			AbilityTemplates;
	local X2AbilityTemplate					Template;
	local X2Effect							Effect;
	local X2Effect_CoveringFire				CoveringEffect;

	// This is the default Sharpshooter Return Fire ability
	// Localization references secondary weapon
	FindAbilityTemplates('ReturnFire', AbilityTemplates);
	foreach AbilityTemplates(Template)
	{
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
	}
	// This is Return Fire for Skirmishers (and potentially others without pistols if added with mods)
	// It is essentially just a copy of the Sharpshooter one but the localization can refer to the primary weapon this way
	FindAbilityTemplates('SkirmisherReturnFire', AbilityTemplates);
	foreach AbilityTemplates(Template)
	{
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
	}
	// This is Return Fire for ADVENT when the Dark Event is active
	// Gets way more dangerous with infinite uses
	FindAbilityTemplates('DarkEventAbility_ReturnFire', AbilityTemplates);
	foreach AbilityTemplates(Template)
	{
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
	}
	// This is Return Fire for the Chosen
	// It is infinite by default but can now be configured
	FindAbilityTemplates('ChosenRevenge', AbilityTemplates);
	foreach AbilityTemplates(Template)
	{
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
}


static function ReactionFireFix()
{
	local Array<X2AbilityTemplate>			AbilityTemplates;
	local Name								AbilityName;
	local X2AbilityTemplate					Template;
	local X2AbilityToHitCalc_StandardAim	StandardAim;
	local X2Condition_UnitEffects			SuppressedCondition;
	local X2Condition_UnitProperty			UnitCondition;

	foreach default.ReactionFireAbilitiesToFix(AbilityName)
	{
		FindAbilityTemplates(AbilityName, AbilityTemplates);
		foreach AbilityTemplates(Template)
		{
			// Make sure these are considered reaction fire and disallow crits
			StandardAim = X2AbilityToHitCalc_StandardAim(Template.AbilityToHitCalc);
			if (StandardAim != none)
			{
				StandardAim.bReactionFire = true;
				StandardAim.bAllowCrit = false;
			}
			StandardAim = X2AbilityToHitCalc_StandardAim(Template.AbilityToHitOwnerOnMissCalc);
			if (StandardAim != none)
			{
				StandardAim.bReactionFire = true;
				StandardAim.bAllowCrit = false;
			}

			// Suppression removes activated Overwatch when used but doesn't prevent passive reaction fire without doing this
			SuppressedCondition = new class'X2Condition_UnitEffects';
			SuppressedCondition.AddExcludeEffect(class'X2Effect_Suppression'.default.EffectName, 'AA_UnitIsSuppressed');
			Template.AbilityShooterConditions.AddItem(SuppressedCondition);

			// TODO: prevent reactions while suppressing, the above suppression check doesn't handle that

			// Panic should prevent reactions
			UnitCondition = new class'X2Condition_UnitProperty';
			UnitCondition.ExcludePanicked = true;
			Template.AbilityShooterConditions.AddItem(UnitCondition);
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
	local X2WeaponTemplate			Template;
	local Array<X2DataTemplate>		DifficultyTemplates;
	local X2DataTemplate			DataTemplate;

	FindItemDataTemplates(WeaponName, DifficultyTemplates);
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


static function FindItemDataTemplates(Name ItemName, out Array<X2DataTemplate> Templates)
{
	local X2ItemTemplateManager			ItemManager;

	Templates.Length = 0;

	ItemManager = class'X2ItemTemplateManager'.static.GetItemTemplateManager();
	ItemManager.FindDataTemplateAllDifficulties(ItemName, Templates);
}


static function FindAbilityTemplates(Name AbilityName, out Array<X2AbilityTemplate> Templates)
{
	local X2AbilityTemplateManager		AbilityManager;
	local Array<X2DataTemplate>			DifficultyTemplates;
	local X2DataTemplate				DataTemplate;
	local X2AbilityTemplate				Template;

	Templates.Length = 0;

	AbilityManager = class'X2AbilityTemplateManager'.static.GetAbilityTemplateManager();
	AbilityManager.FindDataTemplateAllDifficulties(AbilityName, DifficultyTemplates);

	foreach DifficultyTemplates(DataTemplate)
	{
		Template = X2AbilityTemplate(DataTemplate);
		if (Template != none)
		{
			Templates.AddItem(Template);
		}
	}
}
