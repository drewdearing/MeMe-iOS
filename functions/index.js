const functions = require('firebase-functions');
const admin = require('firebase-admin');

admin.initializeApp({
    credential: admin.credential.applicationDefault()
});

var db = admin.firestore();
var FieldValue = admin.firestore.FieldValue;

exports.onPostDelete = functions.firestore
.document('post/{postID}')
.onDelete((snap, context) => {
    let postID = context.params.postID
    let post = snap.data()
    let userDB = db.collection('users').doc(post.uid)
    let postDB = userDB.collection('posts').doc(postID)
    return postDB.delete()
})

exports.onUserPostDelete = functions.firestore
.document('users/{uid}/posts/{postID}')
.onDelete((snap, context) => {
    let postID = context.params.postID
    let postDB = db.collection('post').doc(postID)
    return postDB.delete()
})

exports.upvote = functions.https.onRequest((req, res) => {
    let uid = req.query.uid;
    let postID = req.query.post;
    let postRef = db.collection('post').doc(postID)
    let voteRef = postRef.collection('votes').doc(uid)
    voteRef.get().then((voteDoc) => {
        var deltaUp = 1
        var deltaDown = 0
        if(voteDoc.exists){
            console.log("exists");
            if(voteDoc.data().up){
                deltaUp--
            }
            else{
                deltaDown--
            }
        }
        postRef.update({
            upvotes: FieldValue.increment(deltaUp),
            downvotes: FieldValue.increment(deltaDown)
        }).then(() => {
            postRef.get().then((postDoc) => {
                let postData = postDoc.data();
                voteRef.set({ up: true });
                postRef.update({score: postData.upvotes - postData.downvotes});
                res.status(200).json({
                    upvotes: postData.upvotes,
                    downvotes: postData.downvotes
                });
            });
        }).catch((data) => {
            res.status(400).json(data);
        });
    });
});

exports.downvote = functions.https.onRequest((req, res) => {
    let uid = req.query.uid;
    let postID = req.query.post;
    let postRef = db.collection('post').doc(postID)
    let voteRef = postRef.collection('votes').doc(uid)
    voteRef.get().then((voteDoc) => {
        var deltaUp = 0
        var deltaDown = 1
        if(voteDoc.exists){
            console.log("exists");
            if(voteDoc.data().up){
                deltaUp--
            }
            else{
                deltaDown--
            }
        }
        postRef.update({
            upvotes: FieldValue.increment(deltaUp),
            downvotes: FieldValue.increment(deltaDown)
        }).then(() => {
            postRef.get().then((postDoc) => {
                let postData = postDoc.data();
                voteRef.set({ up: false });
                postRef.update({score: postData.upvotes - postData.downvotes});
                res.status(200).json({
                    upvotes: postData.upvotes,
                    downvotes: postData.downvotes
                });
            });
        }).catch((data) => {
            res.status(400).json(data);
        });
    });
});

exports.getUserPosts = functions.https.onRequest((req, res) => {
    let uid = req.query.uid;
    let time = parseFloat(req.query.timestamp)
    let numPosts = 50;
    if (isNaN(time) || time < 0){
        time = new Date().getTime() * 0.001
    }
    var seconds = parseInt(time)
    var nano = parseInt((time - seconds) * 1000000000)
    let expireTime = (new Date().getTime() * 0.001) - 86400
    let expireSeconds = parseInt(expireTime)
    let expireNano = parseInt((expireTime - expireSeconds) * 1000000000)
    let timestamp = new admin.firestore.Timestamp(seconds, nano)
    let expireTimestamp = new admin.firestore.Timestamp(expireSeconds, expireNano)
    let userRef = db.collection('users').doc(uid).collection('posts').where('timestamp', '<=', timestamp)
    let postIDs = []
    userRef.get().then((posts) => {
        posts.docs.forEach((post) => {
            if(post.exists){
                let postData = post.data()
                let postTimestamp = postData.timestamp.toDate()
                if(postTimestamp <= expireTimestamp.toDate()){
                    post.ref.delete()
                }
                else{
                    postIDs.push({
                        id: post.id,
                        uid: postData.uid,
                        color: postData.color,
                        timestamp: postData.timestamp
                    })
                }
            }
        })
        postIDs.sort((a, b) => {
            return b.timestamp.toDate() - a.timestamp.toDate()
        })
        res.status(200).json({posts: postIDs.slice(0, numPosts)})
    })
})

exports.getDiscoverFeed = functions.https.onRequest((req, res) => {
    let expireTime = (new Date().getTime() * 0.001) - 86400
    let expireSeconds = parseInt(expireTime)
    let expireNano = parseInt((expireTime - expireSeconds) * 1000000000)
    let expireTimestamp = new admin.firestore.Timestamp(expireSeconds, expireNano)
    let numPosts = 50
    let maxScore = parseInt(req.query.maxScore)
    let postIDs = []
    var postRef = db.collection('post')
    if(!isNaN(maxScore)){
        postRef = postRef.where('score', '<=', maxScore)
    }
    return postRef.get().then((posts) => {
        posts.docs.forEach((post) => {
            if(post.exists){
                let postData = post.data()
                let postTimestamp = postData.timestamp.toDate()
                if(postTimestamp <= expireTimestamp.toDate()){
                    post.ref.delete()
                }
                else{
                    postIDs.push({
                        id: post.id,
                        uid: postData.uid,
                        color: postData.color,
                        timestamp: postData.timestamp,
                        upvotes: postData.upvotes,
                        downvotes: postData.downvotes
                    })
                }
            }
        })
        postIDs.sort((a, b) => {
            return (b.upvotes - b.downvotes) - (a.upvotes - a.downvotes)
        })
        res.status(200).json({posts: postIDs.slice(0, numPosts)})
    })
})

exports.getUserFeed = functions.https.onRequest((req, res) => {
    let uid = req.query.uid;
    let time = parseFloat(req.query.timestamp)
    let numPosts = 50
    if (isNaN(time) || time < 0){
        time = new Date().getTime() * 0.001
    }
    var seconds = parseInt(time)
    var nano = parseInt((time - seconds) * 1000000000)
    let expireTime = (new Date().getTime() * 0.001) - 86400
    let expireSeconds = parseInt(expireTime)
    let expireNano = parseInt((expireTime - expireSeconds) * 1000000000)
    let timestamp = new admin.firestore.Timestamp(seconds, nano)
    let expireTimestamp = new admin.firestore.Timestamp(expireSeconds, expireNano)
    let followedUsers = [uid]
    let followingDB = db.collection('users').doc(uid).collection('following')
    followingDB.get().then((following) => {
        let followedPostsDBs = []
        let postIDs = []
        following.docs.forEach((followedUser) => {
            if(followedUser.exists){
                if(followedUser.data().following){
                    followedUsers.push(followedUser.id)
                }
            }
        })
        followedUsers.forEach((user) => {
            followedPostsDBs.push(db.collection('users').doc(user).collection('posts').where('timestamp', '<=', timestamp).get())
        })
        Promise.all(followedPostsDBs).then((postCollections) => {
            postCollections.forEach((postCollection) => {
                postCollection.docs.forEach((post) => {
                    if(post.exists){
                        let postData = post.data()
                        let postTimestamp = postData.timestamp.toDate()
                        if(postTimestamp <= expireTimestamp.toDate()){
                            post.ref.delete()
                        }
                        else{
                            postIDs.push({
                                id: post.id,
                                uid: postData.uid,
                                color: postData.color,
                                timestamp: postData.timestamp
                            })
                        }
                    }
                })
            })
            postIDs.sort((a, b) => {
                return b.timestamp.toDate() - a.timestamp.toDate()
            })
            res.status(200).json({posts: postIDs.slice(0, numPosts)})
        })
    })
})

exports.follow = functions.https.onRequest((req, res) => {
    let uid = req.query.uid
    let followingUID = req.query.following
    let followingUserRef = db.collection('users').doc(followingUID)
    let followerUserRef = db.collection('users').doc(uid)
    let followingRef = followerUserRef.collection('following').doc(followingUID)
    let followerRef = followingUserRef.collection('followers').doc(uid)
    followingRef.get().then((followingDoc) => {
        if(!followingDoc.exists){
            followerUserRef.update({
                numFollowing: FieldValue.increment(1)
            })
            followingRef.set({
                following: true
            })
        }
    })
    return followerRef.get().then((followerDoc) => {
        if(!followerDoc.exists){
            followingUserRef.update({
                numFollowers: FieldValue.increment(1)
            }).then(() => {
                followingUserRef.get().then((followingUserDoc) => {
                    if(followingUserDoc.exists){
                        res.status(200).json({
                            numFollowers: followingUserDoc.data().numFollowers
                        })
                    }
                })
            })
            followerRef.set({
                following: true
            })
        }
        else{
            followingUserRef.get().then((followingUserDoc) => {
                if(followingUserDoc.exists){
                    res.status(200).json({
                        numFollowers: followingUserDoc.data().numFollowers
                    })
                }
            })
        }
    })
})

exports.unfollow = functions.https.onRequest((req, res) => {
    let uid = req.query.uid
    let followingUID = req.query.following
    let followingUserRef = db.collection('users').doc(followingUID)
    let followerUserRef = db.collection('users').doc(uid)
    let followingRef = followerUserRef.collection('following').doc(followingUID)
    let followerRef = followingUserRef.collection('followers').doc(uid)
    followingRef.get().then((followingDoc) => {
        if(followingDoc.exists){
            followerUserRef.update({
                numFollowing: FieldValue.increment(-1)
            })
            followingRef.delete()
        }
    })
    return followerRef.get().then((followerDoc) => {
        if(followerDoc.exists){
            followingUserRef.update({
                numFollowers: FieldValue.increment(-1)
            }).then(() => {
                followingUserRef.get().then((followingUserDoc) => {
                    if(followingUserDoc.exists){
                        res.status(200).json({
                            numFollowers: followingUserDoc.data().numFollowers
                        })
                    }
                })
            })
            followerRef.delete()
        }
        else{
            followingUserRef.get().then((followingUserDoc) => {
                if(followingUserDoc.exists){
                    res.status(200).json({
                        numFollowers: followingUserDoc.data().numFollowers
                    })
                }
            })
        }
    })
})