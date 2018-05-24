using System;
using System.Collections;
using System.Collections.Generic;
using UnityEngine;
using UnityEngine.UI;

[Serializable]
public class PlayerMeta {
	public long updated;
	public long created;
}
[Serializable]
public class PlayerData {
	public string name;
	public int points;
	public PlayerMeta meta;
}
[Serializable]
public class PlayerDataContainer {
	public long time;
	public List<PlayerData> players;
}
public class ServerPoller : Manager<ServerPoller> {

	public string BaseURL = "https://inlight.fool.games/";
	
	[Range(0, 3)]
	public float PollInterval = 0.5f;

	long latestPollTime;

	void Start() {
		StartCoroutine(Poll());
	}

	IEnumerator Poll() {
		while (true) {
			var req = new WWW(BaseURL + "playerupdates/" + latestPollTime);
			yield return req;
			if (req.error == null) {
				var firstLoad = latestPollTime == 0;
				var data = JsonUtility.FromJson<PlayerDataContainer>(req.text);
				// clear initial placeholder leaderboard data if the first server request worked
				if (firstLoad) {
					Leaderboard.Inst.Entries.Clear();
				}
				latestPollTime = data.time;
				// apply new data to leaderboard
				foreach (var player in data.players) {
					var entry = Leaderboard.Inst.Entries.Find(player.name, (e, n) => e.Name == n);
					if (entry == null) {
						entry = new LeaderboardEntry {
							Name = player.name,
							CreatedTime = player.meta.created,
						};
						Leaderboard.Inst.Entries.Add(entry);
					}
					// popups based on point diff
					if (!firstLoad) {
						var pointDiff = player.points - entry.Points;
						for (int i = 0; i < pointDiff; i++) {
							PopupSpawner.Inst.PopupQueue.Add(entry.Name);
						}
					}
					// set points
					entry.Points = player.points;
				}
			} else {
				Debug.LogWarning(req.error);
			}
			yield return new WaitForSeconds(PollInterval);
		}
	}
}
