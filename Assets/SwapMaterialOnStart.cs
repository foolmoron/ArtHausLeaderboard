using System.Collections;
using System.Collections.Generic;
using UnityEngine;
using UnityEngine.UI;

public class SwapMaterialOnStart : MonoBehaviour {

	public Material Material;
	
	void Start() {
		if (GetComponent<Renderer>()) {
			GetComponent<Renderer>().material = Material;
		}
		if (GetComponent<Graphic>()) {
			GetComponent<Graphic>().material = Material;
		}
		enabled = false;
	}
}
