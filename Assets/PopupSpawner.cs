using System.Collections;
using System.Collections.Generic;
using UnityEngine;

public class PopupSpawner : Manager<PopupSpawner> {

	public GameObject PopupPrefab;

	public List<string> PopupQueue = new List<string>();

	[Range(0, 2)]
	public float PopupMinInterval = 0.3f;
	float popupTime;

	public Vector2 SideForceRange;
	public Vector2 UpForceRange;
	public Vector2 AngularForceRange;

	void Awake() {
	}
	
	void Update() {
		if (PopupQueue.Count > 0) {
			popupTime -= Time.deltaTime;
			if (popupTime <= 0) {
				popupTime = PopupMinInterval;
				var popup = Instantiate(PopupPrefab, transform.position, Quaternion.identity);

				var index = Mathf.FloorToInt(Random.value * PopupQueue.Count);
				var item = PopupQueue[index];
				PopupQueue.RemoveAt(index);

				var popupText = popup.GetComponent<PopupText>();
				popupText.Name = item;

				var rb = popup.GetComponent<Rigidbody2D>();
				rb.AddForce(new Vector2((Random.value < 0.5f ? 1 : -1) * Random.Range(SideForceRange.x, SideForceRange.y), Random.Range(UpForceRange.x, UpForceRange.y)), ForceMode2D.Impulse);
				rb.angularVelocity = (Random.value < 0.5f ? 1 : -1) * Random.Range(AngularForceRange.x, AngularForceRange.y);
			}
		}
	}
}
