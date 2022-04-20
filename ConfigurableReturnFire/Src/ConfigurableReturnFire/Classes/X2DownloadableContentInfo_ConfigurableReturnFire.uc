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

var config Int          SecondaryReturnFireShots,
                        PrimaryReturnFireShots,
                        DarkEventReturnFireShots,
                        ChosenReturnFireShots,
                        SecondaryReturnFireChance,
                        PrimaryReturnFireChance,
                        DarkEventReturnFireChance;

var config Bool         SecondaryReturnFireOnlyWhenMiss,
                        PrimaryReturnFireOnlyWhenMiss,
                        DarkEventReturnFireOnlyWhenMiss,
                        ChosenReturnFireOnlyWhenMiss;

var config Array<Name>  ReturnFireWeapons;

static event OnPostTemplatesCreated()
{
    ReturnFireFix();
    AddReturnFireToMoreWeapons();
}


static function ReturnFireFix()
{
    local X2AbilityTemplateManager          AllAbilities;
    local X2AbilityTemplate                 Template;
    local X2Effect                          Effect;
    local X2Effect_ReturnFire               ReturnFireEffect;
    local X2Effect_CoveringFire             CoveringEffect;
    local X2AbilityToHitCalc_StandardAim    StandardAim;
    local X2Condition_UnitEffects           SuppressedCondition;
    local X2Condition_UnitProperty          UnitCondition;
    local Array<Name>                       PistolOverwatchShots;
    local Name                              AbilityName;

    AllAbilities = class'X2AbilityTemplateManager'.static.GetAbilityTemplateManager();

    // This is the default Sharpshooter Return Fire ability
    // Localization references secondary weapon
    Template = AllAbilities.FindAbilityTemplate('ReturnFire');
    foreach Template.AbilityTargetEffects(Effect)
    {
        if (Effect.IsA('X2Effect_ReturnFire'))
        {
            ReturnFireEffect = X2Effect_ReturnFire(Effect);
            ReturnFireEffect.MaxPointsPerTurn = default.SecondaryReturnFireShots;
            ReturnFireEffect.ActivationPercentChance = default.SecondaryReturnFireChance;
	        ReturnFireEffect.bOnlyWhenAttackMisses = default.SecondaryReturnFireOnlyWhenMiss;
            break;
        }
    }
    // This is Return Fire for Skirmishers (and potentially others without pistols if added with mods)
    // It is essentially just a copy of the Sharpshooter one but the localization can refer to the primary weapon this way
    Template = AllAbilities.FindAbilityTemplate('SkirmisherReturnFire');
    foreach Template.AbilityTargetEffects(Effect)
    {
        if (Effect.IsA('X2Effect_ReturnFire'))
        {
            ReturnFireEffect = X2Effect_ReturnFire(Effect);
            ReturnFireEffect.MaxPointsPerTurn = default.PrimaryReturnFireShots;
            ReturnFireEffect.ActivationPercentChance = default.PrimaryReturnFireChance;
	        ReturnFireEffect.bOnlyWhenAttackMisses = default.PrimaryReturnFireOnlyWhenMiss;
            break;
        }
    }
    // This is Return Fire for ADVENT when the Dark Event is active
    // Gets way more dangerous with infinite uses
    Template = AllAbilities.FindAbilityTemplate('DarkEventAbility_ReturnFire');
    foreach Template.AbilityTargetEffects(Effect)
    {
        if (Effect.IsA('X2Effect_ReturnFire'))
        {
            ReturnFireEffect = X2Effect_ReturnFire(Effect);
            ReturnFireEffect.MaxPointsPerTurn = default.DarkEventReturnFireShots;
            ReturnFireEffect.ActivationPercentChance = default.DarkEventReturnFireChance;
	        ReturnFireEffect.bOnlyWhenAttackMisses = default.DarkEventReturnFireOnlyWhenMiss;
            break;
        }
    }
    // This is Return Fire for the Chosen
    // It is infinite by default but can now be configured
    Template = AllAbilities.FindAbilityTemplate('ChosenRevenge');
    foreach Template.AbilityTargetEffects(Effect)
    {
        if (Effect.IsA('X2Effect_CoveringFire'))
        {
            CoveringEffect = X2Effect_CoveringFire(Effect);
            CoveringEffect.MaxPointsPerTurn = default.ChosenReturnFireShots;
            // Chance is already configurable through SoldierSkills
	        CoveringEffect.bOnlyWhenAttackMisses = default.ChosenReturnFireOnlyWhenMiss;
            break;
        }
    }

    // Fixing discrepancies in the actual reaction fire shots
    PistolOverwatchShots.AddItem('PistolOverwatchShot'); // This one is also getting fixed because they share the relevant code
    PistolOverwatchShots.AddItem('PistolReturnFire'); // Is also used by Skirmisher Bullpups despite the name
    PistolOverwatchShots.AddItem('DarkEventAbility_PistolReturnFire');
    // The Chosen use their regular OverwatchShot for the actual shot so it doesn't need fixing

    foreach PistolOverwatchShots(AbilityName)
    {
        Template = AllAbilities.FindAbilityTemplate(AbilityName);
        StandardAim = new class'X2AbilityToHitCalc_StandardAim';
        StandardAim.bReactionFire = true;
        StandardAim.bAllowCrit = false; // This is what is being changed here
        Template.AbilityToHitCalc = StandardAim;
        Template.AbilityToHitOwnerOnMissCalc = StandardAim;
        // Suppression disables all other overwatch, do it for these as well
        SuppressedCondition = new class'X2Condition_UnitEffects';
        SuppressedCondition.AddExcludeEffect(class'X2Effect_Suppression'.default.EffectName, 'AA_UnitIsSuppressed');
        Template.AbilityShooterConditions.AddItem(SuppressedCondition);
        UnitCondition = new class'X2Condition_UnitProperty';
        // Panic should prevent reactions
        UnitCondition.ExcludePanicked = true;
        Template.AbilityShooterConditions.AddItem(UnitCondition);
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
    local X2ItemTemplateManager AllItems;
    local X2WeaponTemplate      Template;
    local Array<X2DataTemplate> DifficultyTemplates;
    local X2DataTemplate        DataTemplate;

    AllItems = class'X2ItemTemplateManager'.static.GetItemTemplateManager();
    Template = X2WeaponTemplate(AllItems.FindItemTemplate(WeaponName));
    if (Template != none)
    {
        if (Template.bShouldCreateDifficultyVariants == true)
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
        else
        {
            if (Template.Abilities.Find('PistolReturnFire') == -1) // Prevent duplicating if another mod already added it
            {
                Template.Abilities.AddItem('PistolReturnFire');
            }
        }
    }
}
