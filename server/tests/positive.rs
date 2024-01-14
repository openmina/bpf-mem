// Copyright (c) Viable Systems
// SPDX-License-Identifier: MIT

async fn get(path: &str, params: &str) -> serde_json::Value {
    use std::env;

    let url = env::var("URL").unwrap();
    let uri = format!("{}{}?{}", url, path, params);
    println!("get {}", uri);
    let res = reqwest::get(&uri).await.unwrap().text().await.unwrap();
    serde_json::from_str(&res).unwrap()
}

fn check(tree: &serde_json::Value, recursion_limit: usize) {
    let tree = tree.as_object().unwrap();
    let value = tree.get("value").unwrap().as_i64().unwrap();
    let cache_value = tree.get("cacheValue").unwrap().as_i64().unwrap();
    assert!(value >= cache_value);
    if let Some(frames) = tree.get("frames") {
        let frames = frames.as_array().unwrap();
        for frame in frames {
            if recursion_limit > 0 {
                check(frame, recursion_limit - 1);
            }
        }
    }
}

#[tokio::test]
async fn positive() {
    let tree = get("/v1/tree", "threshold=0").await;
    check(&tree, 10);
}
