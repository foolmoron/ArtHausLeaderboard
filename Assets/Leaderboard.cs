using System;
using System.Collections;
using System.Collections.Generic;
using UnityEngine;
using UnityEngine.UI;

[Serializable]
public class LeaderboardEntry {
	static int ID;
	public readonly int Id = ID++;

	public string Name;
	public int Points;
	public long CreatedTime;
}
[Serializable]
public class LeaderboardPosition {
	public int TopOffset;
	public float Scale;
}
public class Leaderboard : Manager<Leaderboard> {
	
	public GameObject EntryPrefab;

	public LeaderboardPosition[] Positions;
	public float DefaultScale;
	public float DefaultOffsetStep;

	[Range(0, 0.5f)]
	public float LerpSpeed = 0.1f;

	public List<LeaderboardEntry> Entries = new List<LeaderboardEntry>();
	ListDict<LeaderboardEntry, Text> entryToTexts = new ListDict<LeaderboardEntry, Text>();
	
	void Update() {
		// sort entries
		Entries.Sort((e1, e2) => (e2.Points - e1.Points) != 0 ? e2.Points - e1.Points : e1.CreatedTime.CompareTo(e2.CreatedTime) != 0 ? e1.CreatedTime.CompareTo(e2.CreatedTime) : e1.Id - e2.Id);
		// clear texts with old entries
		for (int i = 0; i < entryToTexts.Count; i++) {
			if (!Entries.Contains(entryToTexts.Keys[i])) {
				Destroy(entryToTexts.Values[i].gameObject);
				entryToTexts.RemoveAt(i);
				i--;
			}
		}
		// new texts for new entries
		for (var i = 0; i < Entries.Count; i++) {
			var entry = Entries[i];
			if (!entryToTexts.ContainsKey(entry)) {
				var newText = Instantiate(EntryPrefab, transform).GetComponent<Text>();
				entryToTexts[entry] = newText;
				LerpToPosition(newText, i, 1);
			}
		}
		// update leaderboard
		for (int i = 0; i < Entries.Count; i++) {
			var entry = Entries[i];
			var text = entryToTexts[entry];
			text.text = entry.Points + "★ " + entry.Name;
			LerpToPosition(text, i, LerpSpeed);
		}
	}

	void LerpToPosition(Text text, int position, float speed) {
		var desiredOffset = position < Positions.Length ? Positions[position].TopOffset : Positions[Positions.Length - 1].TopOffset + DefaultOffsetStep * (position - Positions.Length + 1);
		var desiredScale = position < Positions.Length ? Positions[position].Scale : DefaultScale;
		text.rectTransform.anchoredPosition = text.rectTransform.anchoredPosition.withY(Mathf.Lerp(text.rectTransform.anchoredPosition.y, desiredOffset, speed));
		text.rectTransform.localScale = Vector3.Lerp(text.rectTransform.localScale, Vector3.one * desiredScale, speed);
	}
}
