using System;
using System.Collections;
using System.Collections.Generic;
using UnityEngine;
using UnityEngine.UI;

public class SVOption : MonoBehaviour
{
    [SerializeField] Image BackgroundImage;
    [SerializeField] Image ForegroundImage;
    [SerializeField] Toggle toggle;
    [SerializeField][Range(0,1)] float Saturation=1;
    [SerializeField] [Range(0, 1)] float Value=1;
    public ColorPaletteController ColorPaltte;
    private Color color;
    private void OnEnable()
    {
        ColorPaltte.OnHueChange.AddListener(OnHueChange);
        if (!toggle) toggle = GetComponent<Toggle>();
    }

    private void OnHueChange(float hue)
    {
        if (hue >= 1 - 1.0 / 25 && hue<=1)
        {
            //value ranges from 0 to 1
            float value0to1 = (Value - Saturation + 0.75f) / 1.5f;
            //value ranges from 0.5 to 0.75
            //float value2 = (value0to1 + 0.5f) / 2.0f;
            color = Color.HSVToRGB(0, 0, value0to1);

        }
        else
            color = Color.HSVToRGB(hue, Saturation, Value);
        UpdateSpritesColor();
    }

    public void OnCheckChange(bool isChecked)
    {
        UpdateSpritesColor();
        ColorPaltte.Value = Value;
        ColorPaltte.Saturation = Saturation;

    }
    private void UpdateSpritesColor()
    {
        if (toggle.isOn)
        {
            BackgroundImage.color = color;
            ForegroundImage.color = Color.white;
        }
        else
        {
            BackgroundImage.color = Color.white;
            ForegroundImage.color = color;
        }
    }

    private void OnDisable()
    {
        ColorPaltte.OnHueChange.RemoveListener(OnHueChange);
    }
}
