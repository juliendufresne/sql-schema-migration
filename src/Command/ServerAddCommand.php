<?php

declare(strict_types=1);

namespace JulienDufresne\SQLSchemaMigration\Command;

use Symfony\Component\Console\Command\Command;
use Symfony\Component\Console\Input\InputArgument;
use Symfony\Component\Console\Input\InputInterface;
use Symfony\Component\Console\Output\OutputInterface;

final class ServerAddCommand extends Command
{
    protected function configure()
    {
        parent::configure();
        $this
            ->setName('server:add')
            ->setDefinition(
                [
                    new InputArgument('name', InputArgument::REQUIRED, 'The server name'),
                ]
            );
    }

    protected function execute(InputInterface $input, OutputInterface $output)
    {

    }
}
