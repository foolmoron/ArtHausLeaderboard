using System.Collections;
using System.Collections.Generic;
using UnityEngine;

public class PopupText : MonoBehaviour {

	public string Name;
	public float DeathY = -10;

	public GameObject TrailPrefab;
	public float ExtraTrailOffset = 0.01f;
	[Range(0, 0.5f)]
	public float VelocityTrailOffsetFactor = 0.1f;
	[Range(0.001f, 0.01f)]
	public float FontWidthFactor = 0.0064f;

	TextMesh text;
	Renderer textRenderer;
	Rigidbody2D rb;
	FloatNear leftTrail;
	FloatNear rightTrail;
	float width;

	void Awake() {
		text = GetComponentInChildren<TextMesh>();
		textRenderer = text.GetComponent<Renderer>();
		rb = GetComponent<Rigidbody2D>();
		leftTrail = Instantiate(TrailPrefab, transform.position, Quaternion.identity).GetComponent<FloatNear>();
		rightTrail = Instantiate(TrailPrefab, transform.position, Quaternion.identity).GetComponent<FloatNear>();
	}
	
	void Update() {
		// text
		if (text.text != Name) {
			text.text = Name;
			width = GetTextWidth(text);
		}
		// trail targets
		leftTrail.BaseTarget = transform.TransformPoint(new Vector3(-width / 2 - ExtraTrailOffset, 0, 0)) + rb.velocity.to3() * VelocityTrailOffsetFactor;
		rightTrail.BaseTarget = transform.TransformPoint(new Vector3(width / 2 + ExtraTrailOffset, 0, 0)) + rb.velocity.to3() * VelocityTrailOffsetFactor;
		// die
		if (transform.position.y <= DeathY) {
			Destroy(gameObject);
			Destroy(leftTrail.gameObject);
			Destroy(rightTrail.gameObject);
		}
	}

	public float GetTextWidth(TextMesh tm) {
		var width = 0;
		foreach (var c in tm.text) {
			CharacterInfo info;
			if (tm.font.GetCharacterInfo(c, out info, tm.fontSize, tm.fontStyle)) {
				width += info.glyphWidth;
			}
		}
		return width * tm.characterSize * FontWidthFactor;
	}
}
