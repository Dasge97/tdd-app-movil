<?php

declare(strict_types=1);

namespace App\Service;

use App\Entity\User;
use App\Repository\CommentRepository;
use App\Repository\UserRepository;

class ShadowBanService
{
    public function __construct(
        private readonly UserRepository $userRepository,
        private readonly CommentRepository $commentRepository
    ) {
    }

    public function evaluate(User $author): void
    {
        if ($author->isAiPersona()) {
            return;
        }

        $shouldBan = false;

        // Condition 1: reliabilityScore <= -10
        if ($author->getReliabilityScore() <= -10) {
            $shouldBan = true;
        }

        // Condition 2 + 3: >= 5 comments in 30 days AND >= 40% with negative score
        if (!$shouldBan) {
            $totalIn30Days = $this->commentRepository->countByUserInLast30Days($author->getId());
            if ($totalIn30Days >= 5) {
                $negativeIn30Days = $this->commentRepository->countNegativeByUserInLast30Days($author->getId());
                $ratio = $negativeIn30Days / $totalIn30Days;
                if ($ratio >= 0.40) {
                    $shouldBan = true;
                }
            }
        }

        if ($shouldBan && !$author->isShadowBanned()) {
            $author->setIsShadowBanned(true);
            $this->userRepository->save($author);
        }
    }

    public function reviewBanned(): void
    {
        $bannedUsers = $this->userRepository->findShadowBannedForReview();

        foreach ($bannedUsers as $user) {
            $recentComments = $this->commentRepository->findRecentByUser($user->getId(), 7);

            if (empty($recentComments)) {
                continue;
            }

            $totalScore = 0;
            foreach ($recentComments as $comment) {
                $totalScore += $comment->getScore();
            }

            $avgScore = $totalScore / count($recentComments);

            if ($avgScore >= 0) {
                $newScore = $user->getReliabilityScore() + 5;
                $user->setReliabilityScore($newScore);

                if ($newScore > -10) {
                    $user->setIsShadowBanned(false);
                }

                $this->userRepository->save($user);
            }
        }
    }
}
