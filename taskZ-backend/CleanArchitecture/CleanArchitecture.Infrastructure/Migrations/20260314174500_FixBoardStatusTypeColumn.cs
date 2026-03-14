using CleanArchitecture.Infrastructure.Contexts;
using Microsoft.EntityFrameworkCore.Infrastructure;
using Microsoft.EntityFrameworkCore.Migrations;

#nullable disable

namespace CleanArchitecture.Infrastructure.Migrations
{
    [DbContext(typeof(ApplicationDbContext))]
    [Migration("20260314174500_FixBoardStatusTypeColumn")]
    public class FixBoardStatusTypeColumn : Migration
    {
        protected override void Up(MigrationBuilder migrationBuilder)
        {
            migrationBuilder.Sql(@"
                ALTER TABLE ""BoardStatuses""
                ADD COLUMN IF NOT EXISTS ""Type"" character varying(32) NOT NULL DEFAULT 'custom';
            ");

            // Best-effort backfill for common legacy names.
            migrationBuilder.Sql(@"
                UPDATE ""BoardStatuses""
                SET ""Type"" = 'todo'
                WHERE lower(trim(""Title"")) IN ('todo');
            ");

            migrationBuilder.Sql(@"
                UPDATE ""BoardStatuses""
                SET ""Type"" = 'in_progress'
                WHERE lower(trim(""Title"")) IN ('in progress', 'in_progress', 'progress');
            ");

            migrationBuilder.Sql(@"
                UPDATE ""BoardStatuses""
                SET ""Type"" = 'done'
                WHERE lower(trim(""Title"")) IN ('done', 'completed', 'complete');
            ");
        }

        protected override void Down(MigrationBuilder migrationBuilder)
        {
            migrationBuilder.Sql(@"
                ALTER TABLE ""BoardStatuses""
                DROP COLUMN IF EXISTS ""Type"";
            ");
        }
    }
}
