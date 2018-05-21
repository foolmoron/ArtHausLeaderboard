using System.Collections;
using System.Collections.Generic;
using UnityEngine;

[ExecuteInEditMode]
public class FitToCamera : MonoBehaviour {

	Camera camera;

	void Awake() {
		camera = Camera.main;	
	}
	
	void Update() {
		var aspect = (float)Screen.width / Screen.height;
		var height = camera.orthographicSize * 2;
		var width = height * aspect;
		transform.localScale = new Vector3(width, height, 1);
	}
}
