<?php

declare(strict_types=1);

namespace App\Command;

use App\Service\ShadowBanService;
use Symfony\Component\Console\Attribute\AsCommand;
use Symfony\Component\Console\Command\Command;
use Symfony\Component\Console\Input\InputInterface;
use Symfony\Component\Console\Output\OutputInterface;
use Symfony\Component\Console\Style\SymfonyStyle;

#[AsCommand(
    name: 'app:review-shadow-bans',
    description: 'Revisa y actualiza shadow bans automáticamente'
)]
class ReviewShadowBansCommand extends Command
{
    public function __construct(
        private readonly ShadowBanService $shadowBanService
    ) {
        parent::__construct();
    }

    protected function execute(InputInterface $input, OutputInterface $output): int
    {
        $io = new SymfonyStyle($input, $output);
        $io->title('Shadow Ban Review');

        try {
            $this->shadowBanService->reviewBanned();
            $io->success('Shadow ban review completed successfully.');
        } catch (\Exception $e) {
            $io->error('Error during shadow ban review: ' . $e->getMessage());
            return Command::FAILURE;
        }

        return Command::SUCCESS;
    }
}
