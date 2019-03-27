const functions = require('firebase-functions');
const admin = require('firebase-admin');

admin.initializeApp({
    credential: admin.credential.applicationDefault()
});

var db = admin.firestore();

const calculateVotes = (postID) => {
    let postDB = db.collection('post').doc(postID);
    let votesDB = postDB.collection('votes');
    return votesDB.get().then((votes) => {
        var upvotes = 0;
        var downvotes = 0;
        votes.docs.forEach((vote) => {
            let up = vote.get('up')
            if(up){
                upvotes++;
            }
            else{
                downvotes++;
            }
        });
        postDB.update({
            upvotes: upvotes,
            downvotes: downvotes
        });
    });
}

exports.onVoteCreate = functions.firestore
.document('post/{postID}/votes/{uid}')
.onCreate((snap, context) => {
    return calculateVotes(context.params.postID)
});

exports.onVoteUpdate = functions.firestore
.document('post/{postID}/votes/{uid}')
.onUpdate((change, context) => {
    return calculateVotes(context.params.postID)
});

exports.onVoteDelete = functions.firestore
.document('post/{postID}/votes/{uid}')
.onDelete((snap, context) => {
    return calculateVotes(context.params.postID)
});
