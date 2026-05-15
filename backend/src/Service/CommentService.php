<?php

declare(strict_types=1);

namespace App\Service;

use App\Entity\Comment;
use App\Entity\User;
use App\Repository\CommentRepository;
use App\Repository\DebateRepository;
use App\Repository\UserRepository;
use App\Repository\VoteRepository;

class CommentService
{
    public function __construct(
        private readonly CommentRepository $commentRepository,
        private readonly DebateRepository $debateRepository,
        private readonly UserRepository $userRepository,
        private readonly VoteRepository $voteRepository,
        private readonly ShadowBanService $shadowBanService
    ) {
    }

    public function getComments(int $debateId, ?int $parentId, User $currentUser): array
    {
        $excludeShadowBanned = !$currentUser->isShadowBanned();
        return $this->commentRepository->findByDebate($debateId, $parentId, $excludeShadowBanned);
    }

    /**
     * Returns all comments for a debate (including replies), allowing the caller
     * to group them into a parent → children structure efficiently.
     */
    public function getAllComments(int $debateId, User $currentUser): array
    {
        $excludeShadowBanned = !$currentUser->isShadowBanned();
        return $this->commentRepository->findAllByDebate($debateId, $excludeShadowBanned);
    }

    public function addComment(User $user, int $debateId, ?int $parentId, string $content): Comment
    {
        if (empty(trim($content))) {
            throw new \InvalidArgumentException('content cannot be empty');
        }

        $debate = $this->debateRepository->find($debateId);
        if ($debate === null) {
            throw new \RuntimeException('NOT_FOUND: debate not found');
        }

        $parent = null;
        if ($parentId !== null) {
            $parent = $this->commentRepository->find($parentId);
            if ($parent === null) {
                throw new \RuntimeException('NOT_FOUND: parent comment not found');
            }
        }

        $comment = new Comment();
        $comment->setDebate($debate);
        $comment->setUser($user);
        $comment->setParent($parent);
        $comment->setContent(trim($content));

        $this->commentRepository->save($comment);

        return $comment;
    }

    public function voteComment(User $voter, int $commentId, int $value): void
    {
        if (!in_array($value, [1, -1], true)) {
            throw new \InvalidArgumentException('value must be 1 or -1');
        }

        $comment = $this->commentRepository->find($commentId);
        if ($comment === null) {
            throw new \RuntimeException('NOT_FOUND: comment not found');
        }

        if ($comment->getUser()->getId() === $voter->getId()) {
            throw new \RuntimeException('FORBIDDEN: cannot vote on own comment');
        }

        // Upsert the vote
        $this->voteRepository->upsert($voter->getId(), $commentId, $value);

        // Recalculate comment score
        $this->recalculateScore($comment);

        // Update author's reliability score
        $author = $comment->getUser();
        $author->setReliabilityScore($author->getReliabilityScore() + $value);
        $this->userRepository->save($author);

        // Evaluate shadow ban
        $this->shadowBanService->evaluate($author);
    }

    private function recalculateScore(Comment $comment): void
    {
        $conn = $this->commentRepository->getEntityManager()->getConnection();
        $score = (int) $conn->fetchOne(
            'SELECT COALESCE(SUM(value), 0) FROM votes WHERE comment_id = :id',
            ['id' => $comment->getId()]
        );
        $comment->setScore($score);
        $this->commentRepository->save($comment);
    }

    private function userRepository(): UserRepository
    {
        return $this->userRepository;
    }
}
